variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable   "public_key"   {
  type = string 
}

variable   "bucket_account_name"   {
  type = string  
  default = "bucket-sa"
}
variable   "vmg_account_name"   {
  type = string  
  default = "vmg-sa"
} 
variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "имя сети"
} 

variable "vmg_name" {
  type    = string
  default = "vmg-lamp" 
  description = "имя группы ВМ"
}

variable "lb_name" {
  type    = string
  default = "lb-lamp" 
  description = "имя баланировщика"
}
variable "lb_groupname" {
  type    = string
  default = "lb-lampgroup" 
  description = "имя группы баланировки"
}

# Параметры бакета
variable "bucket" {
  type        = map
  default     = {
    name           = "grpa-storage"
    type           = "COLD" # другие варианты: STANDARD, ICE
    max_size       = 10485760 # Размер бакета в байтах. По умолчанию значение равно 10 Мб
    acl            = "public-read"
    force_destroy  = true # Позволяет удалить бакет вместе с находящимися в нем ресурсами не выдавая ошибки 
  }
  validation {
    condition     = var.bucket.name != null
    error_message = "Не указано имя бакета."
  }
  validation {
    condition     = !can(regex("[^A-Za-z0-9-.]", var.bucket.name))
    error_message = "Имя бакета может содержать только следующие наборы символов a-z, A-Z, 0-9, \"-\" или \".\""
  }
  
  validation {
    condition     = var.bucket.type != null
    error_message = "Не указан тип бакета."
  }
  validation {
    condition     = var.bucket.max_size > 0
    error_message = "Размер  бакета должен быть ненулевым."
  }
  description = "Параметры бакета"
} 

# Ресурсы всех ВМ
variable "vms_resources"{ 
  type = map
  default={ 
        publicvm={  
            cores  = 2
            memory = 1 
            core_fraction = 5
            disk = {
               type = "network-hdd"
               size = 20
            }
        }  
    }
} 
