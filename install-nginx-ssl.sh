#!/bin/bash
set -e

echo "Enter domain name (example: api.example.com):"
read DOMAIN

echo "Enter internal app port (example: 8000):"
read APP_PORT

echo "🔹 Updating system..."
sudo apt update -y

echo "🔹 Installing Nginx & Certbot..."
sudo apt install -y nginx certbot python3-certbot-nginx

echo "🔹 Creating Nginx config for $DOMAIN..."

sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "🔹 Enabling Nginx config..."
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

echo "🔹 Testing and restarting Nginx..."
sudo nginx -t && sudo systemctl restart nginx

echo "🔹 Enabling Nginx to start on boot..."
sudo systemctl enable nginx

echo "🔹 Obtaining SSL certificate..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" --redirect

echo ""
echo "✅ SSL Installed & Auto-Renewal enabled!"
echo "✅ Nginx is running and enabled on boot"

echo ""
echo "✅ DONE!"
echo "Your API is live at: https://$DOMAIN"
echo "Reverse Proxy forwarding → http://127.0.0.1:$APP_PORT"
