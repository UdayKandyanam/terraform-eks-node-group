variable "cluster_name" {
  description = "Name of the existing EKS cluster the node group joins."
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "cluster_name must not be empty."
  }
}

variable "node_group_name" {
  description = "Name of the managed node group."
  type        = string

  validation {
    condition     = length(var.node_group_name) > 0
    error_message = "node_group_name must not be empty."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs the nodes run in. Use private subnets for production clusters."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "instance_types" {
  description = "Instance types for the nodes. Listing more than one type helps when a single type is short on capacity."
  type        = list(string)
  default     = ["t3.large"]

  validation {
    condition     = length(var.instance_types) > 0
    error_message = "instance_types must contain at least one instance type."
  }
}

variable "desired_capacity" {
  description = "Desired number of nodes. The cluster autoscaler or Karpenter may move the real count after creation."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 0
    error_message = "desired_capacity must be zero or more."
  }
}

variable "min_capacity" {
  description = "Minimum number of nodes the group scales down to."
  type        = number
  default     = 1

  validation {
    condition     = var.min_capacity >= 0
    error_message = "min_capacity must be zero or more."
  }
}

variable "max_capacity" {
  description = "Maximum number of nodes the group scales up to."
  type        = number
  default     = 3

  validation {
    condition     = var.max_capacity >= 1
    error_message = "max_capacity must be at least one."
  }
}

variable "disk_size" {
  description = "Root volume size in GiB for each node."
  type        = number
  default     = 50

  validation {
    condition     = var.disk_size >= 20 && var.disk_size <= 100
    error_message = "disk_size must be between 20 and 100 GiB."
  }
}

variable "labels" {
  description = "Kubernetes labels applied to the nodes in this group."
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints applied to the nodes in this group."
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the node group and the IAM role."
  type        = map(string)
  default     = {}
}
