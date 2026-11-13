output "node_group_id" {
  description = "ID of the managed node group."
  value       = aws_eks_node_group.this.id
}

output "node_group_status" {
  description = "Current status of the managed node group."
  value       = aws_eks_node_group.this.status
}

output "node_role_arn" {
  description = "ARN of the IAM role the nodes run as."
  value       = aws_iam_role.nodes.arn
}

output "autoscaling_group_name" {
  description = "Name of the autoscaling group backing the node group. Null until the group reports its resources after creation."
  value       = try(aws_eks_node_group.this.resources[0].autoscaling_groups[0].name, null)
}
