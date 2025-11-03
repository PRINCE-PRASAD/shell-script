#!/bin/bash
set -e

echo "Enter domain name (example: api.example.com):"
read DOMAIN

echo "Enter internal app port (example: 8000):"
read APP_PORT

echo "Enter email for SSL certificate (example: user@example.com):"
read SSL_EMAIL

echo "🔹 Updating system..."
sudo apt update -y

echo "🔹 Installing Nginx & Certbot..."
sudo apt install -y nginx certbot python3-certbot-nginx

echo "🔹 Creating Nginx config for $DOMAIN..."

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;   
    
    # Support 100MB uploads
    client_max_body_size 100M;

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
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/$DOMAIN

echo "🔹 Testing and restarting Nginx..."
sudo nginx -t && sudo systemctl restart nginx

echo "🔹 Enabling Nginx to start on boot..."
sudo systemctl enable nginx

echo "🔹 Obtaining SSL certificate..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL" --redirect

echo "🔹 Enabling auto-renew..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo ""
echo "✅ SSL Installed & Auto-Renewal enabled!"
echo "✅ Email used: $SSL_EMAIL"
echo "✅ Domain: https://$DOMAIN"
echo "✅ Reverse Proxy → http://127.0.0.1:$APP_PORT"
echo ""
echo "✅ DONE!"
