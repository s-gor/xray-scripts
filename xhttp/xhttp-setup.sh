```bash
#!/bin/bash

set -e

echo
echo "=================================="
echo " Xray xHTTP Setup"
echo "=================================="
echo

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

read -p "Enter domain: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "Domain cannot be empty"
    exit 1
fi

CERT_DIR="/root/.acme.sh/${DOMAIN}_ecc"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo
echo "[1/9] Checking Xray..."

if ! command -v xray >/dev/null 2>&1; then
    echo "Xray not found"
    exit 1
fi

echo "OK"

echo
echo "[2/9] Checking Nginx..."

if ! command -v nginx >/dev/null 2>&1; then
    echo "Nginx not found"
    exit 1
fi

echo "OK"

echo
echo "[3/9] Checking certificate..."

if [ ! -d "$CERT_DIR" ]; then
    echo "Certificate directory not found:"
    echo "$CERT_DIR"
    exit 1
fi

echo "OK"

echo
echo "[4/9] Generating UUID..."

UUID=$(xray uuid)

echo "$UUID"

echo
echo "[5/9] Creating backups..."

mkdir -p /root/backups

if [ -f /usr/local/etc/xray/config.json ]; then
    cp /usr/local/etc/xray/config.json \
       /root/backups/config.json.$TIMESTAMP
fi

if [ -f /etc/nginx/sites-available/xhttp.conf ]; then
    cp /etc/nginx/sites-available/xhttp.conf \
       /root/backups/xhttp.conf.$TIMESTAMP
fi

echo "OK"

echo
echo "[6/9] Creating Xray configuration..."

mkdir -p /usr/local/etc/xray

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
            "id": "$UUID"
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

echo "OK"

echo
echo "[7/9] Creating Nginx configuration..."

cat > /etc/nginx/sites-available/xhttp.conf <<EOF
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate     $CERT_DIR/fullchain.cer;
    ssl_certificate_key $CERT_DIR/$DOMAIN.key;

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

ln -sf /etc/nginx/sites-available/xhttp.conf \
       /etc/nginx/sites-enabled/xhttp.conf

echo "OK"

echo
read -p "Install demo web page? (y/n): " INSTALL_PAGE

if [[ "$INSTALL_PAGE" =~ ^[Yy]$ ]]; then

    echo
    echo "[8/9] Installing demo page..."

    mkdir -p /var/www/html

    curl -fsSL \
    https://raw.githubusercontent.com/s-gor/web-lab/main/bitrate-calculator/index.html \
    -o /var/www/html/index.html

    echo "OK"

fi

echo
echo "[9/9] Testing and restarting services..."

xray run -test -config /usr/local/etc/xray/config.json

nginx -t

systemctl restart xray
systemctl restart nginx

echo "OK"

LINK="vless://$UUID@$DOMAIN:443?security=tls&sni=$DOMAIN&type=xhttp&path=%2Fxhttp&encryption=none#xHTTP"

echo "$LINK" > /root/xhttp-link.txt

echo
echo "=================================="
echo "Installation completed"
echo "=================================="
echo
echo "Client link:"
echo
echo "$LINK"
echo
echo "Saved:"
echo "/root/xhttp-link.txt"
echo
echo "Website:"
echo "https://$DOMAIN"
echo
echo "=================================="
```
