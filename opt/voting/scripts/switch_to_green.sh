#!/bin/bash

echo "Switching to GREEN..."

sudo cp /opt/voting/nginx/green.conf /etc/nginx/sites-enabled/default
sudo nginx -s reload