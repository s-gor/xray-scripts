\# Xray xHTTP + Nginx



В этой инструкции рассмотрена установка Xray xHTTP за Nginx на Ubuntu.



Конфигурация проверена на AWS EC2 и использует:



\* Ubuntu 26.04

\* Xray 26.3.27

\* Nginx 1.28.3

\* Let's Encrypt (acme.sh)

\* Dynu DNS



В результате получаем следующую схему:



\* Nginx принимает HTTPS-соединения на порту 443.

\* Веб-страница размещается в `/var/www/html`.

\* Запросы к пути `/xhttp` проксируются на локальный экземпляр Xray.

\* Xray работает на `127.0.0.1:8443` и не доступен извне напрямую.



\## Подготовка домена



В качестве примера используется бесплатный сервис Dynu.



Создайте хост и привяжите его к IP-адресу сервера.



Пример:



```text

ipsec.dynu.net

```



Убедитесь, что имя разрешается в IP вашего сервера:



```bash

ping ipsec.dynu.net

```



После этого можно переходить к настройке сервера.


## Установка Nginx

Обновляем систему:

```bash
apt update && apt upgrade -y
```

Устанавливаем Nginx:

```bash
apt install nginx -y
```

Проверяем состояние службы:

```bash
systemctl status nginx
```

Убедитесь, что сервер отвечает по HTTP.

Откройте в браузере:

```text
http://IP_СЕРВЕРА
```

Если отображается стандартная страница Nginx, можно переходить к получению сертификата.


## Получение сертификата Let's Encrypt

Для получения сертификата используется acme.sh.

Установка:

```bash
curl https://get.acme.sh | sh
```

Перезапускаем сессию или выполняем:

```bash
source ~/.bashrc
```

Выпускаем сертификат:

```bash
~/.acme.sh/acme.sh --issue -d ipsec.dynu.net --webroot /var/www/html
```

После успешного выпуска проверяем наличие файлов:

```bash
ls -l /root/.acme.sh/ipsec.dynu.net_ecc/
```

Должны присутствовать сертификат и приватный ключ.


## Подготовка веб-страницы

В данной конфигурации Nginx выполняет две задачи:

* обслуживает обычный HTTPS-сайт;
* проксирует запросы `/xhttp` на локальный экземпляр Xray.

Поэтому перед получением сертификата разместим простую веб-страницу.

В качестве примера используется проект Web Lab:

```bash
curl -fsSL https://raw.githubusercontent.com/s-gor/web-lab/main/bitrate-calculator/index.html -o /var/www/html/index.html
```

Проверяем:

```text
http://ipsec.dynu.net
```

Страница должна открываться по HTTP.

Использовать можно любую HTML-страницу. В примере применяется калькулятор битрейта из репозитория Web Lab.

## Получение сертификата Let's Encrypt

Для получения сертификата используется acme.sh.

Установка:

```bash
curl https://get.acme.sh | sh
```

Перезапускаем сессию:

```bash
source ~/.bashrc
```

Выпускаем сертификат:

```bash
~/.acme.sh/acme.sh --issue -d ipsec.dynu.net --webroot /var/www/html
```

После успешного выпуска проверяем наличие файлов:

```bash
ls -l /root/.acme.sh/ipsec.dynu.net_ecc/
```

Должны присутствовать сертификат и приватный ключ.




## Установка Xray

Устанавливаем Xray:

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ install
```

Проверяем установленную версию:

```bash
xray version
```

На момент написания инструкции использовалась версия:

```text
26.3.27
```

## Создание конфигурации Xray

Генерируем UUID:

```bash
xray uuid
```

Пример:

```text
e787c639-37e5-487f-9f59-08843dc697ec
```

Создаем файл конфигурации:

```bash
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "ВАШ_UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "path": "/xhttp"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
```

Проверяем конфигурацию:

```bash
xray run -test -config /usr/local/etc/xray/config.json
```

Запускаем службу:

```bash
systemctl restart xray
```

Проверяем прослушиваемый порт:

```bash
ss -tlnp | grep 8443
```

Ожидаемый результат:

```text
127.0.0.1:8443
```

Xray должен слушать только локальный интерфейс и не быть доступным извне напрямую.




Настройка Nginx для xHTTP

Создаем конфигурацию Nginx:

cat > /etc/nginx/sites-available/xhttp.conf <<EOF
server {
    listen 443 ssl http2;
    server_name ipsec.dynu.net;

    ssl_certificate     /root/.acme.sh/ipsec.dynu.net_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/ipsec.dynu.net_ecc/ipsec.dynu.net.key;

    location /xhttp {
        proxy_http_version 1.1;
        proxy_pass http://127.0.0.1:8443;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF

Активируем конфигурацию:

ln -sf /etc/nginx/sites-available/xhttp.conf /etc/nginx/sites-enabled/xhttp.conf

Проверяем конфигурацию:

nginx -t

Если ошибок нет, перезапускаем Nginx:

systemctl restart nginx

Проверяем открытие сайта:

https://ipsec.dynu.net

Должна открыться ранее размещенная веб-страница.

Проверка работы xHTTP

Проверяем доступность пути /xhttp:

curl -vk https://ipsec.dynu.net/xhttp

Ответ может содержать:

HTTP/2 404

Для xHTTP это не является ошибкой. Обычный HTTP-запрос не соответствует протоколу обмена данными Xray-клиента.

Окончательная проверка выполняется только реальным клиентом Xray.

Создание клиентской ссылки

Формат ссылки:

vless://UUID@ipsec.dynu.net:443?security=tls&sni=ipsec.dynu.net&type=xhttp&path=%2Fxhttp&encryption=none#xHTTP

Пример:

vless://e787c639-37e5-487f-9f59-08843dc697ec@ipsec.dynu.net:443?security=tls&sni=ipsec.dynu.net&type=xhttp&path=%2Fxhttp&encryption=none#xHTTP

Импортируйте ссылку в v2rayN или v2rayNG.


## Проверка подключения клиента

После импорта ссылки в клиент включаем профиль и проверяем журнал Xray на сервере:

```bash
journalctl -u xray -f
```

При успешном подключении в журнале появятся строки вида:

```text
from 86.200.xxx.xxx:0 accepted tcp:www.msftconnecttest.com:80
from 86.200.xxx.xxx:0 accepted tcp:client.wns.windows.com:443
```

Это означает, что:

* клиент успешно подключился к серверу;
* запрос прошел через Nginx;
* Nginx передал соединение в Xray;
* Xray принял клиента;
* трафик начал передаваться через сервер.

## Проверка прослушиваемых портов

Проверяем:

```bash
ss -tlnp
```

Ожидаемая схема:

```text
nginx :80
nginx :443
xray  :8443
```

При этом Xray должен слушать только локальный интерфейс:

```text
127.0.0.1:8443
```

а не внешний адрес сервера.

## Итоговая схема

После завершения настройки получаем:

Internet

↓

Nginx :443

↓

/xhttp

↓

127.0.0.1:8443

↓

Xray

Одновременно на том же домене работает обычный веб-сайт:

```text
https://ipsec.dynu.net
```

а путь

```text
https://ipsec.dynu.net/xhttp
```

используется для передачи трафика Xray.

## Что получилось

В результате:

* используется один домен;
* используется один сертификат Let's Encrypt;
* Xray не публикуется напрямую в Интернет;
* Nginx обслуживает веб-сайт и одновременно работает как reverse proxy для xHTTP;
* веб-страницу можно заменить любой страницей или мини-приложением из репозитория Web Lab.

На момент написания инструкции конфигурация успешно протестирована на AWS EC2.





























Проверяем работу HTTPS:

```text
https://ipsec.dynu.net
```

На данном этапе браузер уже должен открывать страницу по HTTPS.










