#создаем облачную сеть
resource "yandex_vpc_network" "develop" {
  name = var.vpc_name 
}

#создаем подсеть 192.168.10.0/24
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "${var.default_zone}"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
