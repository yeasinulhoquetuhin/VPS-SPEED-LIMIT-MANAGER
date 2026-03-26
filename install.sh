#!/bin/bash
URL="https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/tdz-network.b64"
curl -sSL "$URL" | base64 -d | sudo bash