variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "ingress-nginx" {
  description = "Customize ingress-nginx chart, see `ingress-nginx.tf` for supported values"
  type        = any
  default     = {}
}

variable "cert-manager" {
  description = "Customize cert-manager chart, see `cert-manager.tf` for supported values"
  type        = any
  default     = {}
}
