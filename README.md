# Домашнее задание к занятию «Вычислительные мощности. Балансировщики нагрузки»  

### Подготовка к выполнению задания

1. Домашнее задание состоит из обязательной части, которую нужно выполнить на провайдере Yandex Cloud, и дополнительной части в AWS (выполняется по желанию). 
2. Все домашние задания в блоке 15 связаны друг с другом и в конце представляют пример законченной инфраструктуры.  
3. Все задания нужно выполнить с помощью Terraform. Результатом выполненного домашнего задания будет код в репозитории. 
4. Перед началом работы настройте доступ к облачным ресурсам из Terraform, используя материалы прошлых лекций и домашних заданий.

---
## Задание 1. Yandex Cloud 

**Что нужно сделать**

1. Создать бакет Object Storage и разместить в нём файл с картинкой:

 - Создать бакет в Object Storage с произвольным именем (например, _имя_студента_дата_).
 - Положить в бакет файл с картинкой.
 - Сделать файл доступным из интернета.
 
2. Создать группу ВМ в public подсети фиксированного размера с шаблоном LAMP и веб-страницей, содержащей ссылку на картинку из бакета:

 - Создать Instance Group с тремя ВМ и шаблоном LAMP. Для LAMP рекомендуется использовать `image_id = fd827b91d99psvq5fjit`.
 - Для создания стартовой веб-страницы рекомендуется использовать раздел `user_data` в [meta_data](https://cloud.yandex.ru/docs/compute/concepts/vm-metadata).
 - Разместить в стартовой веб-странице шаблонной ВМ ссылку на картинку из бакета.
 - Настроить проверку состояния ВМ.
 
3. Подключить группу к сетевому балансировщику:

 - Создать сетевой балансировщик.
 - Проверить работоспособность, удалив одну или несколько ВМ.
4. (дополнительно)* Создать Application Load Balancer с использованием Instance group и проверкой состояния.

Полезные документы:

- [Compute instance group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance_group).
- [Network Load Balancer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer).
- [Группа ВМ с сетевым балансировщиком](https://cloud.yandex.ru/docs/compute/operations/instance-groups/create-with-balancer).

## 1. Создание бакета и размещение файлов в нем

Создание бакета вынесено в отдельный модуль, расположенный в [папке](modules/bucket)

```
terraform {
  required_providers {
    yandex = { source = "yandex-cloud/yandex"
    }
  } 
  required_version = ">=0.13" 
}

// Создаем статический ключ доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "статический ключ доступа для объектного хранилища"
}

// Создаем бакет 
resource "yandex_storage_bucket" "this" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket                = var.bucket.name
  folder_id             = var.folder_id
  default_storage_class = var.bucket.type
  acl                   = var.bucket.acl
  max_size              = var.bucket.max_size
  force_destroy         = var.bucket.force_destroy
   
  depends_on = [
    yandex_iam_service_account.sa,
    yandex_resourcemanager_folder_iam_member.sa-editor
  ]
}
```

[main.tf](modules/bucket/main.tf)

2. Файл размещаем через программу winscp:
   - в программе выбираем создание нового подключения ***Amazon S3***
   - в качестве имени хоста указываем значение ***storage.yandexcloud.net*** 
   - в качестве идентификатора ключа доступа используем значение ***static_key_id***
   - в качестве секретного ключа доступа используем значение ***static_key_secret***

![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_5.png)

После подключения вставляем копируем файл изображения в бакет.

Нажимаем правой кнопкой мыши по файлу и выбираем команду **Файловые пользовательские команды -> Сгенерировать URL для протокола HTTP**
Получаем диалоговое окно со ссылкой на файл в бакете. Нажимаем кнопку "Копировать", чтобы скопировать адрес в буфер обмена.

![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_6.png)

![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_7.png)

В итоге файл доступен по [ссылке](http://storage.yandexcloud.net/grpa-storage/gosling.jpg). Т.к. при создании бакета использовалась предопределенная ACL - public-read, то файл уже доступен на чтение из интернета.

# 2. Создание группы ВМ в public подсети фиксированного размера с шаблоном LAMP и веб-страницей, содержащей ссылку на картинку из бакета

Создание группы ВМ сделано в виде отдельного модуля, который доступен в [папке](modules/vmgroup)

```
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
```

[main.tf](modules/vmgroup/main.tf)

2. Картинка из бакета публикуется на стартовой странице путем добавления разметки в [cloud-init.yml](cloud-init.yml):

   ```
      write_files:
        - content: |
            <html lang="ru">
               <head>
                  <meta charset="UTF-8">
                  <title>Картинка</title>
               </head>
               <body>
                <h2>Картинка из бакета:</h2>
                <img src='http://storage.yandexcloud.net/grpa-storage/gosling.jpg'/>
               </body>
            </html>
          path: /var/www/html/index.html
   ```

3. Проверка состояния ВМ осуществляется добавления блока **health_check** в группу ВМ и имеет вид:
   
   ```
      health_check {
        interval = 60 # Интервал между проверками. Указывается в секундах
        timeout = 5 # Указывается в секундах
        healthy_threshold = 2 # Количество успешных запросов после которых экземпляр признается успешным, может принимать значения 0 или от 2 до 10. 
        unhealthy_threshold = 2 # Количество неуспешных запросов после которых экземпляр признается неуспешным, может принимать значения 0 или от 2 до 10
        tcp_options {
            port = 80
        }
      } 
   ```

В итоге в консоли yandex видим:

- Создались 3 машины с образом LAMP:

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_4.png)
  
- Создалась группа машин состоящая из этих 3 машин:

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_8.png)

## 3. Подключение группы инстансов к  к сетевому балансировщику

Создание балансировщика нагрузки сделано в виде отдельного модуля, который доступен в [папке](modules/networklb)

```
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
```

[main.tf](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/modules/networklb/main.tf)

2. Развернуть балансировщик можно отдельной командой: ```terraform apply --target module.networklb```

3. Вид yandex-консоли с развернутым балансировщиком:

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_9.png)

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_10.png)

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_11.png)

4. В процессе обновления группы ВМ:

  - Происходит удаление ВМ по 1 за раз :

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_13.png)  

  - Проверка доступности новых экземпляров ВМ
    
  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_14.png)

5. Вид страницы с фото:

  ![изображение](https://github.com/stepynin-georgy/hw_cloud_2/blob/main/img/Screenshot_12.png)

---
## Задание 2*. AWS (задание со звёздочкой)

Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.

**Что нужно сделать**

Используя конфигурации, выполненные в домашнем задании из предыдущего занятия, добавить к Production like сети Autoscaling group из трёх EC2-инстансов с  автоматической установкой веб-сервера в private домен.

1. Создать бакет S3 и разместить в нём файл с картинкой:

 - Создать бакет в S3 с произвольным именем (например, _имя_студента_дата_).
 - Положить в бакет файл с картинкой.
 - Сделать доступным из интернета.
2. Сделать Launch configurations с использованием bootstrap-скрипта с созданием веб-страницы, на которой будет ссылка на картинку в S3. 
3. Загрузить три ЕС2-инстанса и настроить LB с помощью Autoscaling Group.

Resource Terraform:

- [S3 bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Launch Template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template).
- [Autoscaling group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group).
- [Launch configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration).

Пример bootstrap-скрипта:

```
#!/bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>My cool web-server</h1></html>" > index.html
```
### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.
