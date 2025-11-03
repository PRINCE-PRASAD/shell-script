#!/bin/bash
set -e

echo "Enter domain name (example: app.example.com):"
read DOMAIN

echo "Enter internal app port (example: 8501):"
read APP_PORT

echo "Enter email for SSL certificate (example: user@example.com):"
read SSL_EMAIL

echo " Updating system..."
sudo apt update -y

echo " Installing Nginx & Certbot..."
sudo apt install -y nginx certbot python3-certbot-nginx

echo " Creating Nginx config for $DOMAIN..."

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    # Support 100MB uploads
    client_max_body_size 100M;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Streamlit websocket path
    location /_stcore/stream {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

echo " Enabling Nginx config..."
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/$DOMAIN

echo " Testing and restarting Nginx..."
sudo nginx -t && sudo systemctl restart nginx

echo " Enabling Nginx to start on boot..."
sudo systemctl enable nginx

echo " Obtaining SSL certificate..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"

echo " Enabling auto-renew..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo ""
echo " Streamlit-ready HTTPS Reverse Proxy"
echo " WebSockets working"
echo " 100M file upload limit"
echo " SSL Installed & Auto-Renew enabled"
echo " Domain: https://$DOMAIN"
echo " Reverse Proxy → http://127.0.0.1:$APP_PORT"
echo ""
echo " DONE!"
