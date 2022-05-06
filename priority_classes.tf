resource "kubernetes_priority_class" "normal" {
  metadata {
    name = "normal"
  }
  description    = "Normal priority for user pods"
  value          = 100
  global_default = true
}

resource "kubernetes_priority_class" "high_priority" {
  metadata {
    name = "high-priority"
  }
  description = "High priority for user pods"
  value       = 1000
}

resource "kubernetes_priority_class" "highest_priority" {
  metadata {
    name = "highest-priority"
  }
  description = "Highest priority for user pods"
  value       = 10000
}
