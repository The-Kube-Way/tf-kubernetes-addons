output "velero_config" {
  value = {
    endpoint        = local.velero.default_backup_storage_location.s3_url
    region          = local.velero.default_backup_storage_location.s3_region
    bucket          = local.velero.default_backup_storage_location.s3_bucket
    credentials     = local.velero.credentials
    restic_password = local.velero.restic_password
  }
  sensitive = true
}