terraform {
  required_providers {
    yandex = { source = "yandex-cloud/yandex"
    }
  } 
  required_version = ">=0.13" 
}

provider "yandex" {
    token     = var.token
    cloud_id  = var.cloud_id
    folder_id = var.folder_id
    zone      = var.default_zone
 }

module "bucket"{ 
  source     = "./modules/bucket"
  folder_id    = var.folder_id 
  account_name = var.bucket_account_name
  bucket       = var.bucket
}

module "vmgroup"{ 
  source     = "./modules/vmgroup"
  vmg_name       = var.vmg_name
  vpc_name       = var.vpc_name
  folder_id      = var.folder_id 
  default_zone   = var.default_zone
  account_name   = var.vmg_account_name 
  vms_resources  = var.vms_resources  
  lb_netgroupname   = var.lb_groupname
  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}

module "networklb"{ 
  source     = "./modules/networklb" 
  lb_name        = var.lb_name
  vmg_id       = module.vmgroup.vmg_id
}

#инициализация публичной ВМ
data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
 vars={
     public_key=var.public_key   
 }
}
