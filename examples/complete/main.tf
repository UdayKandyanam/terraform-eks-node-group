terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# The cluster itself is created outside this module. This example assumes an
# existing cluster named example-platform and a VPC with three private
# subnets. The subnet IDs below are placeholders, replace them with real IDs
# from your own VPC before running this.
module "eks_node_group" {
  source = "../../"

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

  taints = []

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

output "node_group_id" {
  description = "ID of the node group created by the example."
  value       = module.eks_node_group.node_group_id
}

output "node_role_arn" {
  description = "ARN of the IAM role the example nodes run as."
  value       = module.eks_node_group.node_role_arn
}
