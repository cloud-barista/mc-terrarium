#!/bin/bash

# DCS (DevStack Cloud Service) Instance Initialization Script
# This script is executed when the instance first boots

# Update package list and install essential packages
apt-get update
apt-get install -y curl wget htop vim nginx

# Create simple HTML page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>DCS Instance - ${instance_name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .info { background: #f4f4f4; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .success { color: #4CAF50; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">✅ DCS Instance Running</h1>
        <div class="info">
            <h3>Instance Information</h3>
            <p><strong>Instance:</strong> ${instance_name}</p>
            <p><strong>Hostname:</strong> \$(hostname)</p>
            <p><strong>Private IP:</strong> $(hostname -I | awk '{print $1}')</p>
            <p><strong>Boot Time:</strong> $(date)</p>
        </div>
        <div class="info">
            <h3>Status</h3>
            <p>✅ Nginx Web Server Running</p>
            <p>✅ System Ready for Testing</p>
        </div>
    </div>
</body>
</html>
EOF

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Log completion
echo "$(date): DCS instance ${instance_name} setup completed" >> /var/log/dcs-init.log