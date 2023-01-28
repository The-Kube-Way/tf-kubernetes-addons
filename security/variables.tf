variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "falco" {
  description = "Customize falco chart, see `falco.tf` for supported values"
  type        = any
  default     = {}
}
