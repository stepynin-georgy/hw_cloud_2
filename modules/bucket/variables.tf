variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  sensitive   = true
}

variable   "account_name"   {
  type = string  
  default = "bucket-sa"
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
