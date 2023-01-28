variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "tigera-operator" {
  description = "Customize tigera-operator chart, see `tigera-operator.tf` for supported values"
  type        = any
  default     = {}
}
