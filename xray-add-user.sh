bash <<'EOF'
set -e

CONFIG="/usr/local/etc/xray/config.json"

UUID=$(xray uuid)

TMP=$(mktemp)

jq --arg uuid "$UUID" \
'.inbounds[0].settings.clients += [{"id":$uuid}]' \
"$CONFIG" > "$TMP"

cat "$TMP" > "$CONFIG"
rm -f "$TMP"

chmod 644 "$CONFIG"
chown root:root "$CONFIG"

echo "[1] Testing config..."

xray run -test -config "$CONFIG"

echo "[2] Restarting Xray..."

systemctl restart xray

PUBLIC_KEY=$(cat /usr/local/etc/xray/public.key)

SHORT_ID=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' "$CONFIG")

IP=$(curl -s4 ifconfig.me)

echo
echo "=============================="
echo "CLIENT LINK:"
echo
echo "vless://$UUID@$IP:443?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=www.microsoft.com&sid=$SHORT_ID&spx=%2F#Xray-Reality"
echo
echo "=============================="

EOF
