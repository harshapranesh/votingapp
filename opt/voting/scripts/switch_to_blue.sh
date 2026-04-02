#!/bin/bash

echo "Switching to BLUE..."

sudo cp /opt/voting/nginx/blue.conf /etc/nginx/sites-enabled/default
sudo nginx -s reload