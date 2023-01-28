variable "helm_defaults" {
  description = "Customize default Helm behavior"
  type        = any
  default     = {}
}

variable "kube-prometheus" {
  description = "Customize kube-prometheus chart, see `kube-prometheus.tf` for supported values"
  type        = any
  default     = {}
}

variable "loki" {
  description = "Customize loki chart, see `loki.tf` for supported values"
  type        = any
  default     = {}
}

variable "grafana" {
  description = "Customize grafana chart, see `grafana.tf` for supported values"
  type        = any
  default     = {}
}

variable "promtail" {
  description = "Customize promtail chart, see `promtail.tf` for supported values"
  type        = any
  default     = {}
}

variable "kubernetes_event_exporter" {
  description = "Customize kubernetes event exporter chart, see `kubernetes_event_exporter.tf` for supported values"
  type        = any
  default     = {}
}
