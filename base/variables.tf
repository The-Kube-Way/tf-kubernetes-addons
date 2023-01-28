variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "priority_classes" {
  description = "Customize priority classes, see `priority_classes.tf` for supported values"
  type        = any
  default     = {}
}

variable "kubernetes-replicator" {
  description = "Customize kubernetes-replicator chart, see `kubernetes-replicator.tf` for supported values"
  type        = any
  default     = {}
}
