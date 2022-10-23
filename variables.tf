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

variable "velero" {
  description = "Customize velero chart, see `velero.tf` for supported values"
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

variable "falco" {
  description = "Customize falco chart, see `falco.tf` for supported values"
  type        = any
  default     = {}
}

variable "kubernetes-replicator" {
  description = "Customize kubernetes-replicator chart, see `kubernetes-replicator.tf` for supported values"
  type        = any
  default     = {}
}

variable "tigera-operator" {
  description = "Customize tigera-operator chart, see `tigera-operator.tf` for supported values"
  type        = any
  default     = {}
}
