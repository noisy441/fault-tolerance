#создаем облачную сеть
resource "yandex_vpc_network" "netology-lan" {
  name = "netology-lan"
}

#создаем подсеть zone A
resource "yandex_vpc_subnet" "lan_a" {
  name           = "lan_a-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.netology-lan.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

