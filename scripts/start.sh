#!/bin/sh

# Startup script for G-Network Social Media App
echo "🚀 Starting G-Network Social Media App..."

# Check if files exist
echo "📁 Checking files..."
ls -la /usr/share/nginx/html/
echo "Health file exists:" $(ls -la /usr/share/nginx/html/health)

# Test nginx configuration
echo "🔧 Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration error"
    cat /etc/nginx/nginx.conf
    exit 1
fi

# Start nginx in background to test
echo "🌐 Starting nginx server..."
nginx

# Wait a moment for nginx to start
sleep 2

# Test health endpoint locally
echo "🏥 Testing health endpoint..."
curl -f http://localhost/health || echo "❌ Health check failed locally"
curl -f http://localhost/ || echo "❌ Root endpoint failed"

# Check if nginx is running
echo "📊 Nginx processes:"
ps aux | grep nginx

# Check port binding
echo "🔌 Port binding:"
netstat -tlnp | grep :80 || echo "Port 80 not bound"

# Stop nginx and start in foreground
nginx -s quit
sleep 1

echo "🚀 Starting nginx in foreground..."
exec nginx -g 'daemon off;'