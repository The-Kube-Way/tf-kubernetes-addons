locals {
  priority_classes = merge(
    {
      enabled          = false
      normal           = true
      high_priority    = true
      highest_priority = true
    },
    var.priority_classes
  )
}
resource "kubernetes_priority_class" "normal" {
  count = local.priority_classes["enabled"] && local.priority_classes["normal"] ? 1 : 0
  metadata {
    name = "normal"
  }
  description    = "Normal priority for user pods"
  value          = 100
  global_default = true
}

resource "kubernetes_priority_class" "high_priority" {
  count = local.priority_classes["enabled"] && local.priority_classes["high_priority"] ? 1 : 0
  metadata {
    name = "high-priority"
  }
  description = "High priority for user pods"
  value       = 1000
}

resource "kubernetes_priority_class" "highest_priority" {
  count = local.priority_classes["enabled"] && local.priority_classes["highest_priority"] ? 1 : 0
  metadata {
    name = "highest-priority"
  }
  description = "Highest priority for user pods"
  value       = 10000
}
