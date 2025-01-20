#образе ОС ubuntu
data "yandex_compute_image" "ubuntu" {
  family = local.ubuntu_image_family 
}

#образе ОС lamp (apachy+mysql+php)
data "yandex_compute_image" "lamp" {
  image_id = "fd827b91d99psvq5fjit"
}
