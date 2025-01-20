terraform {
  required_providers {
    yandex = { source = "yandex-cloud/yandex"
    }
  } 
  required_version = ">=0.13" 
}

// Создаем статический ключ доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "статический ключ доступа для объектного хранилища"
}

// Создаем бакет 
resource "yandex_storage_bucket" "this" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket                = var.bucket.name
  folder_id             = var.folder_id
  default_storage_class = var.bucket.type
  acl                   = var.bucket.acl
  max_size              = var.bucket.max_size
  force_destroy         = var.bucket.force_destroy
   
  depends_on = [
    yandex_iam_service_account.sa,
    yandex_resourcemanager_folder_iam_member.sa-editor
  ]
}
