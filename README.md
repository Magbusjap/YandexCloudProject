# Создание и настройка виртуальной машины, развертывание n8n и создание AI-ассистентов

Подробные шаги по созданию и развертыванию ноды n8n на виртуальной машине Yandex Cloud, и на своем домене. 
Подробные шаги по настройке AI-ассистентов.
Данная инструкция поможет вам развернуть сервис n8n на своем сервере и со своим доменом. Проект - рабочий. 

## Проведенные тесты над ошибками

- bad webhook: Webhook can be set up only on ports 80, 88, 443 or 8443 (fix)
- An HTTPS URL must be provided for webhook (fix)
- Workflow could not be activated (fix)
- Lost connection to the server (fix)
- 502 Bad Gateway (Nginx upstream) (fix)
- 401 Unauthorized при обращении к /rest/push?pushRef= (fix)
- Предупреждение Mismatching encryption keys из n8n (fix)
- ERR_UNEXPECTED_X_FORWARDED_FOR от Express rate‑limit (fix) 
- Connection reset by peer в логе Nginx (fix) 
- Connection refused при curl http://127.0.0.1:5678 (fix)

---

## Последние изменения проекта (обновлен 17.04.2025)

- Создана и настроена Виртуальная машина (Ubuntu 20.04 LTS)
- Установлен Docker / docker‑compose
- Развернут n8n 1.88.0 в контейнере
- Подключен SSL (DomainSSL от REG.RU)
- Налажена работоспособность прокси через Nginx (HTTPS → :5678)
- Настроена работоспособность токена Telegram Trigger API через веб-хук
- Проверен CI / автоматизация deploy на ошибки


---

## Главные изменения в проекте (обновлен 17.04.2025)

1. Внесены изменения в файлы
- n8n (docker-compose.yml), при котором соединение с токеном Telegram Trigger обрывался
- удален дубликат прокси
- Nginx/прокси (mydomain), при котором отсутствовали некоторые строки конфигурации и получившие ошибку «Lost connection to the server»

2. История устранения критической ошибки Telegram Trigger
- «Workflow could not be activated / bad webhook / Lost connection to the server / 502 Bad Gateway»

3. Диагностика
- проверил `A`‑записи DNS и прокинутый 443 → :5678.
- `curl -I http://127.0.0.1:5678` — контейнер отвечает 200 OK.
- `tail -f /var/log/nginx/error.log` — `Connection reset by peer` → проблема между Nginx и n8n.
- `curl -s https://api.telegram.org/bot<token>/getWebhookInfo` — пустой `url`.

4. Исправления
   
- В docker-compose.yml добавлены переменные окружения:
  - `environment:`
    - `N8N_COOKIE_DOMAIN=.ВашДомен.ru`
    - `N8N_ENCRYPTION_KEY=<32‑символьный base64>`
    - `WEBHOOK_URL=https://ВашДомен.ru/`
- В конфиге Nginx:
    - `proxy_buffering off;         # иначе рвётся SSE`
    - `proxy_read_timeout  3600;`
    - `proxy_send_timeout  3600;`
    - `proxy_set_header X-Forwarded-Proto $scheme;`
 
- Очищены старые webhooks Telegram:
    - `curl -s "https://api.telegram.org/bot<token>/deleteWebhook"`
- Полный перезапуск: `Полный перезапуск: docker-compose down && docker-compose up -d`

5. Результат
- `getWebhookInfo` возвращает URL вида `https://ВашДомен.ru/webhook/<uuid>/webhook`.
  - В n8n → Test step → успешно ловит `/start`.
  - `17.04 05:40  ✚ N8N_COOKIE_DOMAIN`
  - `17.04 05:42  ✚ N8N_ENCRYPTION_KEY`
  - `17.04 05:45  ✚ WEBHOOK_URL=https://ВашДомен.ru/`
  - `17.04 05:47  ✚ Nginx proxy_* timeouts`
  - `17.04 05:50  − Bad TLSv1 ciphers`
  - `17.04 05:55  ♻ docker-compose up -d`
  - `17.04 05:57  ✅ Telegram Trigger ответил 200 OK`



## Функционал (обновлен 16.04.2025)

- Создание, настройка и развертывание через SSH
- Создание виртуальной машины на Yandex Cloud
- Установка и настройка Docker
- Развертывание n8n
- Подключение своего домена к ноде n8n
- Автоматизация процесса
- Настройка SSL и конфигурации Nginx


--- 

## Технологии (обновлен 17.04.2025)

- Ubuntu 20.04 LTS (Yandex Cloud), ​vCPU 2, RAM 2GB, SSD 50GB
- Git Bash for Windows
- Docker
- n8n
- ВашДомен.ru
- SSL Domain
- Bash-deploy файл
- nginx файл
- Json-логи (jq)

--- 

## Создание 

  1. Перед созданием ВМ необходимо сгенерировать SSH-ключ. Команда в Git Bash терминале:

     Определить папку, где нужно создать ключ. Например:
     - `cd "/d/ваш относительный путь"`
     
     После чего создать ключ
     - `ssh-keygen -t rsa -b 4096 -C "твой_email@example.com"`
     
     rsa - это имя ключа
  3. Создать ВМ в Yandex Cloud. Выбор ОС: Ubuntu 20.04 LTS (за ее стабильность и большую документацию)

     Перед созданием необходимо создать новый ssh-ключ в вашей ВМ. Для этого скопируйте открытую часть

     ssh-ключа с локальной папки в настройки ВМ.
  5. Создайте docker-compose.yml с нужной конфигурацией (вложен в проект)

     Если используете подключение для теста, то пропишите:
      - N8N_PROTOCOL=http
      - WEBHOOK_TUNNEL_URL=http://<PUBLIC_IP>
      - N8N_SECURE_COOKIE=false
     
     Начальные настройки конфигурации есть в файле n8n-raw.env


--- 

## Установка (обновлен 17.04.2025)

  1. После установки в настройках ВМ у вас будет предоставлен часть командной строки. Полная команда для входа в ВМ в терминале выглядит так:
     - `ssh -i "D:\Ваш путь до ключа\id_rsa" вашлогин@ваш ip от ВМ`
     
     `id_rsa` - это имя открытого ssh-ключа

     Это метот входа в вашу ВМ через по закрытому SSH-ключу, где id_rsa - открытая часть, а rsa - закрытая часть ключа.
  1.5. Каждый раз, как вылетаете из ВМ, нужно логиниться снова.
  3. Обновить списки пакетов и установить обновления:
     - `sudo apt update`
     - `sudo apt upgrade`
  4. Установить Docker
     - `sudo apt install docker.io docker-compose -y`
  5. Запустить Docker
     - `sudo systemctl start docker`
     - `sudo systemctl enable docker`
  6. В терминале перейти в репозиторий, где находится файл docker-compose.yml. Далее выполнить команду
     - `scp -i id_rsa docker-compose.yml ВашЛогин@Ваш ip от ВМ:~/`
     
     После чего данный файл будет скопирован в ВМ.
  7. Добавить пользователя в группу docker:
     - `sudo usermod -aG docker $USER`
  8. Для того, чтобы файл docker-compose.yml заработал, вам нужен 🔑 ключ шифрования.

      Если в вашей ВМ нет ключа шифрования, на вашем сервере пропишите:
     - `openssl rand -base64 24` - Нужно скопировать 32 символа без пробелов и вставить в строку: `N8N_ENCRYPTION_KEY=сгенерированный_32‑символьный_ключ_без_пробелов`
    
     Если вы получаете ошибку `502` на вашем сайте, значит у вас уже имеется ключ шифрования. Откроем файл настроек, чтобы скопировать старый ключ:
     - `docker run --rm -it \ -v ~/.n8n:/data alpine cat /data/config | grep encryptionKey` Получите строку вида: `"encryptionKey":"lT4YpXOOqUV7xg5L1j6TUxaXnNsmYsP"`
     
  9. Перейти в систему, чтобы обновились группы. Проверить работу Docker:
     - `docker ps`
     
     Запустить:
     - `docker-compose up -d`
  10. Установить Nginx:
     - `sudo apt update`
     - `sudo apt install nginx -y`


--- 

## Настройка

  1. На хост-системе (то есть на ВМ) проверьте, кому принадлежит директория ~/.n8n:
     - `ls -la ~/.n8n`
  2. Измените владельца и права так, чтобы UID и GID соответствовали пользователю node внутри контейнера (обычно это 1000:1000). Например:
     - `sudo chown -R 1000:1000 ~/.n8n`
     - `sudo chmod -R 770 ~/.n8n`
     
     chown -R 1000:1000 ~/.n8n — рекурсивно передаёт владение файлам и папкам пользователю с UID 1000 и группе 1000.

     chmod -R 770 ~/.n8n — даёт право чтения/записи/выполнения владельцу и группе, но закрывает доступ для «остальных».
  4. Перезапустите контейнер:
     - `docker-compose down`
     - `docker-compose up -d`
  5. Посмотреть логи n8n:
     - `docker-compose logs -f`

ВНИМАНИЕ! Для подключения к ноду n8n есть 2 варианта: либо отказаться от безопасного подключения, либо привязать официальный сайт n8n, либо купить свой домен и настроить SSL.
Отключить безопасное соединение вы можете в файле: docker-compose.yml
Файл с исходными данными: n8n-raw.env
В моем случае, это покупка домена .ru


--- 

## Автоматизация

  1. Создать файл deploy.sh для автроматизации рутинных задач в терминале Bash.
    
     Основные настройки:
     - `cd "/d/путь к файлу" || { echo "Не удалось перейти в директорию"; exit 1; }`

     Сюда помещаются любые команды

     - `echo "Деплой завершён успешно."`
  2. Сделать файл исполняемым. В терминале прописать:
     - `chmod +x deploy.sh`
  3. Запуск скрипта:
     - `./deploy.sh`
       или
     - `bash deploy.sh`
    

 ---     

## Подключение и настройка своего домена к n8n (обновлен 17.04.2025)

При покупке домена .ru на сайте Reg.ru был предоставлен Бесплатный DomainSSL сертификат на 6 мес. Поэтому настройка вручную от Let's Encrypt не потребовалась.
По желанию, можете добавить Let's Encrypt в случае возникновения ошибки.
Вместо "ВашДомен.ru", подставьте ваш настоящий домен, как указано в примерах ниже.

  1. Настройте А-запись:

     Найдите раздел управления DNS-записями для вашего домена и установите A-запись, которая указывает на публичный IP-адрес вашей ВМ.

     Пример:
        - **Имя/хост:** @ (или оставьте пустым для корневого домена)   
        - **Тип:** A
        - **Значение:** ваш_публичный_IP (например, 51.250.31.91)
    
     Если хотите, чтобы www.ВашДомен.ru работал, установите CNAME-запись для `www`, которая ссылается на ваш основной домен (например, @ или ВашДомен.ru).
  3. Скачайте следующие сертификаты в разделе SSL:
     - **certificate.crt** – это ваш основной сертификат домена. Имеет 1 блок открытого ключа.
     - **certificate_ca.crt** – это промежуточный и коренной сертификаты в одном. Имеет 2 блока открытого ключа.
     - **certificate.key** — приватный ключ
  4. После скачивания трех сертификатов вам необходимо соединить: `certificate.crt` и `certificate_ca.crt`.
     - В текстовом редакторе скопируйте блок целиком из `certificate.crt` и вставьте в начале документа (т.е. `certificate_ca.crt`) скупированный блок ключа.
     - Переименуйте `certificate_ca.crt` в => `fullchain.crt`.
  6. В Bash перейдите в папку с сертификатами. Например:
     - `cd "/d/0. Job, Learn, Chill etc/Clouds/Yandex Cloud/"`

     Проверить файлы:
     - `ls -i`
  7. Скопировать сертификаты: `fullchain.crt` и `certificate.key` по отдельности из компьютера в ВМ. Например:
     - `scp -i "/d/0. Job, Learn, Chill etc/Clouds/Yandex Cloud/SSH/id_rsa" certificate_ca.crt ВашЛогинВМ@Ваш ip от ВМ:~/`
    
     Путь папки - это путь к вашему SSH-ключу.
  9. Залогиньтесь в ВМ и создайте новый путь:
     - `sudo mkdir -p /etc/ssl/НазваниеПапки/`

     Проверить файлы в ВМ, чтобы убедиться, что файлы успешно скопированы:
     - `ls -l ~/`
  10. Скопируйте сертификаты из коренной папки в новую созданную папку:
     - `sudo cp certificate.ca.crt /etc/ssl/НазваниеПапки/`
    
     Проверить скопированные файлы:
     - `ls -l /etc/ssl/ВашДомен/`
  11. Скачайте из проекта файл mydomain и переименуйте на ваше доменное имя (например, ВашДомен.ru). Откройте текстовым редактором и внесите изменения:
     - `server_name ВашДомен www.ВашДомен.ru;`

      Вместо **ВашДомен** укажите название вашего домена
      
      Вместо **www.ВашДомен.ru** укажите название вашего домена
     
     - `ssl_certificate /etc/ssl/ВашДомен.ru/certificate.crt;`
     - `ssl_certificate_key /etc/ssl/ВашДомен.ru/certificate.key;`
     - `ssl_trusted_certificate /etc/ssl/ВашДомен.ru/certificate_ca.crt`
    
     Вместо **mydomain** укажите название вашего домена + .ru
  11. Активируйте сайт и проверьте конфигурацию Nginx
      
     Создайте символическую ссылку в директории sites-enabled:
     - `sudo ln -s /etc/nginx/sites-available/ВашДомен.ru /etc/nginx/sites-enabled/`
    
     Проверьте корректность конфигурации Nginx:
     - `sudo nginx -t`
    
     Если всё настроено верно, команда скажет, что тест конфигурации прошёл успешно. Затем перезапустите Nginx:
     - `sudo systemctl reload nginx`


---

## Настройка переменных окружения n8n

  Обновите ваш docker-compose.yml так, чтобы он использовал доменное имя и https:
  - `N8N_HOST=ВашДомен.ru`
  - `N8N_PROTOCOL=https`
  - `WEBHOOK_TUNNEL_URL=https://ВашДомен.ru` (опционально, если нужны тесты)


---

## Работа с ошибками

Для удобства некоторых команд рекомендую установить `jq`:
  - `sudo apt update && sudo apt install -y jq`

- Если возникают ошибки при работе с консолью или изменении данных, исрользуйте root-права (`sudo`). Например, если надо создать или изменить файл:
  - `sudo nano /etc/nginx/sites-available/ФайлДанных`
    
- Проверка проски:
  - `tail -f /var/log/nginx/error.log`
  - `tail -f /var/log/nginx/access.log | grep /rest/push `
    
- Ошибки на test:
  - `docker-compose logs -f n8n`
 
- Проверка токена API Telegram Trigger (с предустановленным `jq`):
  - `curl -s "https://api.telegram.org/botТОКЕН_API/getWebhookInfo" | jq`
 
- Если нужно убедиться, что контейнер слушает порт, напр. 5678:
  - `docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"` или
  - `docker-compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`

- Убедитесь, что контейнер действительно запущен 
  - `docker-compose ps`

- Просмотр логов:
  - `docker‑compose logs --tail=50` 
  - `sudo tail -f /var/log/nginx/error.log` (логи Nginx)
  - `sudo tail -f /var/log/nginx/access.log` (логи Nginx) или 
  - `sudo tail -f /var/log/nginx/access.log | grep /rest/push` (логи Nginx с доп. параметром проверки)

- Посмотреть последние логи контейнера:
  - `docker-compose logs --tail=100 n8n`

- Быстрый тест без Nginx:
  - `curl -I http://127.0.0.1:5678`
 
- Проверка логов n8n:
  - `docker-compose logs -f n8n`
  - `docker compose logs --tail=50 -f n8n`
 
- Проверка на отзывчикость веб-хука:
  - `docker-compose logs -f n8n | grep -i webhook`

- Проверка конфигов:
  - `sudo nginx -t`
 
- Просмотр error‑log:
  - `tail -f /var/log/nginx/error.log`
  - `docker-compose logs -f`
 
- Если были правки в прокси, перезапустите Nginx:
  - `sudo systemctl reload nginx`
 
- Если отсутствует какой либо Ключ шифрования. На вашем хосте выполните:
  - `openssl rand -hex 32` и добавьте получившееся значение в `docker‑compose.yml`

- Проверка Cookie. Если вылазит ошибка подключения к API, в браузере через среду разработчика (F12).
  - В верхнем меню найдите вкладку `Application`. Затем внизу в левой колонке найдите `Cookie`. Интересует сам сайт, кликните на него.
  - В выпадающем списке найдите `n8n-auth`. В поле `Value` находится Токен. Скопируйте его. Далее через терминал на вашей ВМ укажите:
    - `curl -I -b "n8n-auth=ВАШ_ДЛИННЫЙ_ТОКЕН" https://ВашДомен.ru/rest/push?pushRef=test`
   
      Вместо `ВАШ_ДЛИННЫЙ_ТОКЕН` укажите токен, который вы скопировали.
      
    - Так же можете прописать: `JWT=$(echo 'ВАШЕ_ЗНАЧЕНИЕ_n8n-auth') curl -I -b "n8n-auth=$JWT" https://ВашДомен.ru/rest/push?pushRef=test`
     

- Если по каким-то причинам вы не можете разобраться со старым Ключом шифрования. Переименуйте (через удаление) том с настройками:
   - `mv ~/.n8n ~/.n8n.bak.$(date +%s) docker compose up -d`


     

     



     
