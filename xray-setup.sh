#!/bin/bash

set -e

bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ install

echo "[1] Generating Reality keys..."

UUID=$(xray uuid)

REALITY=$(xray x25519)

PRIVATE_KEY=$(echo "$REALITY" | grep "PrivateKey:" | awk '{print $2}')
PUBLIC_KEY=$(echo "$REALITY" | grep "PublicKey" | awk '{print $3}')

SHORT_ID=$(openssl rand -hex 8)

IP=$(curl -s4 ifconfig.me)

mkdir -p /usr/local/etc/xray

echo "[2] Writing config..."

cat > /usr/local/etc/xray/config.json <<EOT
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
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
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "serverNames": [
            "www.microsoft.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
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
EOT

echo "[3] Saving PublicKey..."

echo "$PUBLIC_KEY" > /usr/local/etc/xray/public.key

echo "[4] Testing config..."

xray run -test -config /usr/local/etc/xray/config.json

echo "[5] Starting service..."

systemctl restart xray

LINK="vless://$UUID@$IP:443?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=www.microsoft.com&sid=$SHORT_ID&spx=%2F#Xray-Reality"

echo "$LINK" > /root/client-link.txt

echo
echo "=============================="
echo "CLIENT LINK:"
echo
echo "$LINK"
echo
echo "Saved:"
echo "/root/client-link.txt"
echo "/usr/local/etc/xray/public.key"
echo "=============================="
echo
