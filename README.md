# Common Kubernetes helm charts using Terraform

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![tf-kubernetes-addons](https://github.com/The-Kube-Way/tf-kubernetes-addons/actions/workflows/terraform.yaml/badge.svg?branch=master)](https://github.com/The-Kube-Way/tf-kubernetes-addons/actions/workflows/terraform.yaml)

This project aims to provide widely used Helm Charts as Terraform module to reduce the cost of maintaining multiple homogeneous clusters.


## Usage

Users are **highly encouraged** to pin a specific commit hash

```terraform
module "kubernetes-addons" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons?ref=$COMMIT_HASH"
}
```

When updating the hash, use `terraform plan` to verify that the changes that will be applied are what you expect.

# Customize Helm Charts

Each helm chart can be customized using parameters.
Check *.tf files for available parameters.

```terraform
module "kubernetes-addons" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons?ref=$COMMIT_HASH"
  loki = {
    enabled              = true
    s3_enabled           = true
    s3_endpoint          = "XXX"
    s3_region            = "XXX"
    s3_bucket            = "XXX"
    s3_access_key_id     = "XXX"
    s3_secret_access_key = "XXX"
    cpu_limit            = "200m"
    memory_limit         = "256Mi"
  }
  promtail = {
    enabled = true
  }
  kubernetes_event_exporter = {
    enabled = true
  }
  cert-manager = {
    enabled = true
  }
  velero = {
    enabled = true
    restic_password = XXX
    credentials = <<VALUES
[default]
aws_access_key_id = XXX
aws_secret_access_key = XXX
  }
  kube-prometheus = {
    enabled = true
    persistence = false
  }
}
```

# Chart updates

Charts version are automatically updated using [Renovate](https://renovatebot.com/).