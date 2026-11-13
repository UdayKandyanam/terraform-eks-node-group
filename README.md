# Terraform EKS Node Group

A reusable Terraform module that creates an Amazon EKS managed node group, plus the IAM role the nodes need to join the cluster and pull images. I wrote it the way I want node groups defined on a platform team: one small module, typed inputs with guardrails, and tests that run without AWS credentials.

The module creates:

- An `aws_eks_node_group` with parameterized scaling, instance types, disk size, labels, and taints
- An `aws_iam_role` for the nodes with the three standard managed policies attached: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and `AmazonEC2ContainerRegistryReadOnly`

The EKS cluster itself is created outside this module. The module joins a node group to a cluster that already exists.

## Usage

```hcl
module "eks_node_group" {
  source = "github.com/UdayKandyanam/terraform-eks-node-group"

  cluster_name    = "example-platform"
  node_group_name = "general-workers"
  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1",
    "subnet-0123456789abcdef2",
  ]

  instance_types   = ["t3.large", "t3.xlarge"]
  desired_capacity = 3
  min_capacity     = 2
  max_capacity     = 6
  disk_size        = 50

  labels = {
    workload = "general"
    team     = "platform"
  }

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
```

A complete root module that calls this module lives in `examples/complete`. It targets region us-east-1 and uses placeholder subnet IDs from a fictional VPC, so swap in real subnet IDs from your own VPC before applying it.

## Inputs

| Name | Type | Default | Required | Description |
| ---- | ---- | ------- | -------- | ----------- |
| cluster_name | string | n/a | yes | Name of the existing EKS cluster the node group joins. |
| node_group_name | string | n/a | yes | Name of the managed node group. |
| subnet_ids | list(string) | n/a | yes | Subnet IDs the nodes run in. Use private subnets for production clusters. |
| instance_types | list(string) | ["t3.large"] | no | Instance types for the nodes. Listing more than one type helps when a single type is short on capacity. |
| desired_capacity | number | 2 | no | Desired number of nodes. The cluster autoscaler or Karpenter may move the real count after creation. |
| min_capacity | number | 1 | no | Minimum number of nodes the group scales down to. |
| max_capacity | number | 3 | no | Maximum number of nodes the group scales up to. |
| disk_size | number | 50 | no | Root volume size in GiB for each node. |
| labels | map(string) | {} | no | Kubernetes labels applied to the nodes in this group. |
| taints | list(object) | [] | no | Kubernetes taints applied to the nodes in this group. |
| tags | map(string) | {} | no | Tags applied to the node group and the IAM role. |

## Outputs

| Name | Description |
| ---- | ----------- |
| node_group_id | ID of the managed node group. |
| node_group_status | Current status of the managed node group. |
| node_role_arn | ARN of the IAM role the nodes run as. |
| autoscaling_group_name | Name of the autoscaling group backing the node group. Null until the group reports its resources after creation. |

## Design choices

**Managed node group over self-managed nodes.** AWS handles node replacement and AMI updates for managed groups, and the update config in this module caps unavailable nodes at one during an update. A self-managed group gives more control over the image and bootstrap script, and costs the team the operational work that comes with it. For general worker capacity, managed is the right default.

**IAM lives in the module.** A node group that cannot join the cluster or pull images fails in ways that look like cluster problems. Keeping the role and its three policy attachments next to the node group means the pair is always created together, in the right order, and torn down together.

**Validation as guardrails.** Inputs fail early when a wrong value is a real failure: empty subnet and instance type lists, disk sizes outside 20 to 100 GiB, and negative capacities are all rejected by variable validation. The scaling relationship, min no greater than desired and desired no greater than max, spans three variables, so it is enforced by a lifecycle precondition on the node group resource. That keeps the check working on every Terraform version the module supports.

**Labels and taints are inputs, not afterthoughts.** Scheduling behavior is part of what a node group is. Passing labels and taints through dynamic blocks keeps one module useful for general pools and for dedicated pools that only some workloads may land on. Each taint entry sets a key, an optional value, and an effect such as NO_SCHEDULE.

## Running the tests

The tests use the Terraform test framework with a mock AWS provider, so they need no AWS credentials and never touch a real account.

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform test
```

The test file covers three runs: scaling values pass from variables to the node group unchanged, labels land on the node group, and a scaling setup with min greater than max is rejected.

## Limits

- No launch template support yet, so custom AMIs, extra volumes, and custom bootstrap scripts are out of scope for now.
- No IRSA or EKS add-on management. Cluster add-ons such as the VPC CNI and kube-proxy, and IAM roles for service accounts, belong in a companion module rather than in this one.
- One node group per call. Call the module once per pool.

## Roadmap

1. Launch template support for custom AMIs and bootstrap configuration.
2. An EKS add-ons companion module covering the standard add-ons and IRSA roles.
3. A multi node group example showing general and dedicated pools side by side.

## License

MIT, see LICENSE.
