# Xray Reality Scripts

![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-blue)
![Xray](https://img.shields.io/badge/Xray-26.3.27-green)
![Status](https://img.shields.io/badge/Status-Working-success)

Автоматическая установка Xray Reality и создание клиентских подключений.

Проект предназначен для быстрого развертывания сервера Xray Reality на Ubuntu и Debian без ручного редактирования конфигурационных файлов.

Без панелей управления, без веб-интерфейсов и без дополнительной инфраструктуры. 

Только Bash, Systemd, JSON и штатные инструменты Linux.

Цель проекта > реальная практике DevOps > когда сервер(а) можно развернуть, проверить и сопровождать с помощью обычных скриптов и средств операционной системы.

> [!NOTE]
> Подключитесь к серверу по SSH и выполните:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/s-gor/xray-scripts/main/xray-setup.sh | bash
> ```
>
> Через несколько секунд будет выдана готовая клиентская ссылка для v2rayN/v2rayNG.

---

## Быстрый старт

Установка сервера:

```bash
curl -fsSL https://raw.githubusercontent.com/s-gor/xray-scripts/main/xray-setup.sh | bash
```

Создание нового клиентского подключения:

```bash
curl -fsSL https://raw.githubusercontent.com/s-gor/xray-scripts/main/xray-add-user.sh | bash
```

Просмотр клиентской ссылки:

```bash
cat /root/client-link.txt
```

Просмотр PublicKey:

```bash
cat /usr/local/etc/xray/public.key
```

Проверка сервиса:

```bash
systemctl status xray --no-pager
```

Ожидаемый результат:

```text
Active: active (running)
```

---

## Структура проекта

| Файл             | Назначение                                   |
| ---------------- | -------------------------------------------- |
| xray-setup.sh    | Установка и первоначальная настройка сервера |
| xray-add-user.sh | Создание нового клиентского подключенияя     |
| README.md        | Документация проекта                         |

---

## Что делает xray-setup.sh

Скрипт автоматически:

* устанавливает Xray;
* генерирует UUID;
* генерирует Reality-ключи;
* создаёт ShortID;
* создаёт рабочий config.json;
* проверяет конфигурацию;
* запускает сервис;
* формирует готовую клиентскую ссылку;
* сохраняет PublicKey для дальнейшего управления пользователями.

---

## Что делает xray-add-user.sh

Скрипт автоматически:

* генерирует новый UUID;
* добавляет пользователя в конфигурацию;
* проверяет конфигурацию;
* перезапускает сервис;
* выводит готовую клиентскую ссылку.

---

## Возможные предупреждения при установке

Во время установки могут появляться сообщения вида:

```text
rm: cannot remove '/etc/systemd/system/xray.service.d/10-donot_touch_multi_conf.conf': No such file or directory

rm: cannot remove '/etc/systemd/system/xray@.service.d/10-donot_touch_multi_conf.conf': No such file or directory

warning: The following are the actual parameters for the xray service startup.
warning: Please make sure the configuration file path is correctly set.
```

Это не является ошибкой.

Установщик Xray пытается удалить служебные файлы от предыдущих установок и выводит информационные сообщения о параметрах запуска сервиса.

После установки рекомендуется проверить состояние сервиса:

```bash
systemctl status xray --no-pager
```

Если отображается:

```text
Active: active (running)
```

то сервер установлен и работает корректно.

---

## Удаление Xray

Полное удаление:

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ remove --purge
```

---

## Проверено на

* Ubuntu 24.04/26.04 LTS
* AWS EC2 (t3.micro)
* Xray 26.3.27
* v2rayN
* v2rayNG

---

## Что можно изучить на этом проекте

- Bash scripting
- GitHub и GitHub Raw
- JSON-конфигурации
- Systemd
- Работа с переменными и шаблонами в Bash
- Автоматическая генерация конфигурационных файлов
- Xray Reality
- Автоматизация развёртывания серверов

---

## Автор

Ser.Gor

Учебный проект по автоматизации установки и сопровождения Xray Reality.

Network Security & Cloud Technologies
