#!/bin/bash
set -e

APP_URL="http://localhost:8000"

HEALTH=$(curl -fsS "$APP_URL/health")
echo "$HEALTH"

DEPLOYED_VERSION=$(echo "$HEALTH" | sed -n 's/.*"sha": *"\([^"]*\)".*/\1/p')

if [ -z "$DEPLOYED_VERSION" ]; then
  echo "Health check failed: SHA missing"
  exit 1
fi

echo "Health check successful. Running SHA: $DEPLOYED_VERSION"
