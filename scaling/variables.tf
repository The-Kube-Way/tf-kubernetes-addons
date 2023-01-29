variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "cluster-autoscaler" {
  description = "Customize cluster-autoscaler chart, see `cluster-autoscaler.tf` for supported values"
  type        = any
  default     = {}
}

