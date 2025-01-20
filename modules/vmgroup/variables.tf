variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  sensitive   = true
}
  
variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable   "account_name"   {
  type = string  
  default = "vmg-sa"
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

variable "lb_netgroupname" {
  type    = string
  default = "lb-lampgroup" 
  description = "имя сетевой группы балансировки"
} 

variable "lb_apigroupname"{
  type    = string
  default = null 
  description = "имя прикладной группы балансировки"
}

variable "metadata" {
  type = map(string)
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
