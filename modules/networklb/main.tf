terraform {
  required_providers {
    yandex = { source = "yandex-cloud/yandex"
    }
  } 
  required_version = ">=0.13" 
}

# Сетевой балансировщик нагрузки
resource "yandex_lb_network_load_balancer" "publiclb" {
  name =  var.lb_name

  listener {
    name = "${var.lb_name}-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = data.yandex_compute_instance_group.vmg.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
  depends_on = [
    data.yandex_compute_instance_group.vmg
  ]
}

# Получаем предварительно созданную группу ВМ по идентификатору. 
data "yandex_compute_instance_group" "vmg"{
  instance_group_id =  var.vmg_id 
}
