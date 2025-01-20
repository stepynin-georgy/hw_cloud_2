terraform {
  required_providers {
    yandex = { source = "yandex-cloud/yandex"
    }
  } 
  required_version = ">=0.13" 
}

#создаем публичную группу ВМ
resource "yandex_compute_instance_group" "publicvmg" { 
  name               = var.vmg_name
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.sa.id
  instance_template {
    platform_id               = "standard-v1"

    resources{
      cores  = var.vms_resources.publicvm.cores
      memory = var.vms_resources.publicvm.memory 
      core_fraction = var.vms_resources.publicvm.core_fraction
    } 
    boot_disk {
      initialize_params {
        image_id = data.yandex_compute_image.lamp.image_id
        type = var.vms_resources.publicvm.disk.type
        size = var.vms_resources.publicvm.disk.size
      }
    }
    scheduling_policy { preemptible = true }

    network_interface { 
      network_id = "${yandex_vpc_network.develop.id}"
      subnet_ids = ["${yandex_vpc_subnet.public.id}"]
      nat = true 
    }
    metadata = {
         for k, v in var.metadata : k => v 
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  allocation_policy {
    zones = [var.default_zone]
  }
  deploy_policy {
    max_unavailable = 1
    max_creating = 3
    max_expansion = 1
    max_deleting = 1
  }
  health_check {
    interval = 60 # Интервал между проверками. Указывается в секундах. Не рекомендуется указывать большие значения. Иначе долго будет подниматься группа.
    timeout = 10 # Указывается в секундах
    healthy_threshold = 2 # Количество успешных запросов после которых экземпляр признается успешным
    unhealthy_threshold = 2 # Количество неуспешных запросов после которых экземпляр признается неуспешным
    http_options {
        port = 80
        path = "/"
    }
  } 
  dynamic "load_balancer" {
    for_each = var.lb_netgroupname !=null?[var.lb_netgroupname]:[]
    content{
      target_group_name        = load_balancer.value
      target_group_description = "Группа балансировки к которой будет подключен балансировщик"
    }
  } 
  dynamic "application_load_balancer" {
    for_each = var.lb_apigroupname !=null?[var.lb_apigroupname]:[]
    content{
      target_group_name        = application_load_balancer.value
      target_group_description = "Группа балансировки к которой будет подключен балансировщик"
    }
  } 
  depends_on = [
    yandex_iam_service_account.sa,
    yandex_resourcemanager_folder_iam_member.sa-admin
  ]
}  
