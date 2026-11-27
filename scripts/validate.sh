#!/bin/bash
set -e

APP_URL="http://localhost:8000"

curl -f "$APP_URL/health"

DEPLOYED_VERSION=$(curl -fsS "$APP_URL/health" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

if [ "$DEPLOYED_VERSION" != "$APP_VERSION" ]; then
  echo "Version mismatch! Expected: $APP_VERSION, Got: $DEPLOYED_VERSION"
  exit 1
fi

echo "Health check and version validation successful: $DEPLOYED_VERSION"
