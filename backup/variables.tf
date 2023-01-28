variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "velero" {
  description = "Customize velero chart, see `velero.tf` for supported values"
  type        = any
  default     = {}
}
