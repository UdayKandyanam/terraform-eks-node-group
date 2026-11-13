mock_provider "aws" {}

variables {
  cluster_name     = "example-platform"
  node_group_name  = "general-workers"
  subnet_ids       = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  instance_types   = ["t3.large"]
  desired_capacity = 3
  min_capacity     = 2
  max_capacity     = 6
  disk_size        = 50
}

run "scaling_config_passes_through" {
  command = plan

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].desired_size == var.desired_capacity
    error_message = "Desired size on the node group does not match desired_capacity."
  }

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].min_size == var.min_capacity
    error_message = "Min size on the node group does not match min_capacity."
  }

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].max_size == var.max_capacity
    error_message = "Max size on the node group does not match max_capacity."
  }

  assert {
    condition     = contains(aws_eks_node_group.this.instance_types, "t3.large")
    error_message = "Instance types from the variables did not reach the node group."
  }
}

run "labels_land_on_node_group" {
  command = plan

  variables {
    labels = {
      workload = "general"
      team     = "platform"
    }
  }

  assert {
    condition     = aws_eks_node_group.this.labels["workload"] == "general"
    error_message = "The workload label did not land on the node group."
  }

  assert {
    condition     = aws_eks_node_group.this.labels["team"] == "platform"
    error_message = "The team label did not land on the node group."
  }
}

run "scaling_validation_rejects_min_above_max" {
  command = plan

  variables {
    min_capacity     = 5
    desired_capacity = 4
    max_capacity     = 3
  }

  expect_failures = [
    aws_eks_node_group.this,
  ]
}
