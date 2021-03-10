#!/bin/bash
sudo apt-get update
sudo apt-get install nginx
sudo mkdir -p /var/www/названиедомена/html

cat <<EOF > /var/www/названиедомена/html/index.html
<html>
<head>
<title>Welcome to название названиедомена!</title>
</head>
<body>
<h1>Success!  The названиедомена server block is working!</h1>
</body>
</html>
EOF

sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/названиедомена
cat <<EOF > /etc/nginx/sites-available/названиедомена
server {
listen 80;
listen [::]:80;
root /var/www/названиедомена/html;
index index.html index.htm index.nginx-debian.html;
server_name названиедомена www.названиедомена;
location / {
try_files $uri $uri/ =404;
}
}
EOF
sudo ln -s /etc/nginx/sites-available/названиедомена /etc/nginx/sites-enabled/
sudo systemctl start nginx
sudo systemctl enable nginx