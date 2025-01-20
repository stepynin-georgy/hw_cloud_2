variable "vmg_id" {
  type    = string
  default = null 
  description = "идентификатор группы ВМ"
}

variable "lb_name" {
  type    = string
  default = "lb-lamp" 
  description = "имя баланировщика"
}  
