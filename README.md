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
    restic_password = "XXX"
    credentials = <<VALUES
[default]
aws_access_key_id = XXX
aws_secret_access_key = XXX
VALUES
    backup_storage_location = {
        enabled             = true
        read_only           = false
        s3_url              = "XXX"
        s3_region           = "XXX"
        s3_force_path_style = false
        s3_bucket           = "XXX"
      }
  }
  kube-prometheus = {
    enabled = true
    persistence = true
    alertmanager_config = <<VALUES
[...]
VALUES
    thanos_enabled              = true
    thanos_s3_endpoint          = "XXX"
    thanos_s3_region            = "XXX"
    thanos_s3_bucket            = "XXX"
    thanos_s3_access_key_id     = "XXX"
    thanos_s3_secret_access_key = "XXX"
  }
  grafana = {
    enabled = true
    pvc = "pvc-grafana"
  }
  ingress-nginx= {
    enabled = true
    admission_webhook = true
    config = {
      enable-ocsp = "true"
      ssl-protocols = "TLSv1.2 TLSv1.3"
      server-tokens = "false"
    }
    tcp = {
      53 = "default/nsd:53"
    }
    udp = {
      53 = "default/nsd:53"
    }
  }
}
```

# Chart updates

Chart versions are automatically updated using [Renovate](https://renovatebot.com/).
Major versions are merged manually.
