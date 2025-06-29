# Считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2204_lts" {
 family = "ubuntu-2204-lts"
}

# Создание виртуальных машин
resource "yandex_compute_instance" "vm" {
 count = 2
 name = "vm${count.index + 1}"
 hostname = "vm${count.index + 1}"
 platform_id = "standard-v3"
 zone = "ru-central1-a"

 resources {
 cores = 2
 memory = 1
 core_fraction = 20
 }

 boot_disk {
 initialize_params {
 image_id = data.yandex_compute_image.ubuntu_2204_lts.id
 type = "network-hdd"
 size = 10
 }
 }

 metadata = {
 user-data = file("./cloud-init.yml")
 serial-port-enable = "true"
 }

 scheduling_policy {
 preemptible = true
 }

 network_interface {
 subnet_id = yandex_vpc_subnet.lan_a.id
 nat = true
 }
}


# Создание таргет-группы
resource "yandex_lb_target_group" "my-target" {
  name      = "my-target"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.lan_a.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.lan_a.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }
}

# Создание сетевого балансировщика
resource "yandex_lb_network_load_balancer" "netology-balancer" {
  name = "netology-balancer"
  listener {
    name = "listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.my-target.id
    healthcheck {
      name = "http"
        http_options {
          port = 80
          path = "/"
        }
    }
  }
}

output "balancer_details" {
  value = {
    listener     = yandex_lb_network_load_balancer.netology-balancer.listener.*
  }
}

# Создание файла инвентаризации
resource "local_file" "inventory" {
 content = <<EOF

[yandex_compute_instance]
${yandex_compute_instance.vm[0].network_interface[0].nat_ip_address}
${yandex_compute_instance.vm[1].network_interface[0].nat_ip_address}

EOF
 filename = "./hosts.ini"
}
