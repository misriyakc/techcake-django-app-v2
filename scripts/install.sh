#!/bin/bash
set -e

REGION="ap-south-1"
ACCOUNT="900360460976"
REPO="djangov2"

APP_VERSION=$(aws ssm get-parameter \
  --name "/techcake/app/APP_VERSION" \
  --region "$REGION" \
  --query "Parameter.Value" \
  --output text)

docker stop django-app || true
docker rm django-app || true

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin \
    "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

docker pull "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO:$APP_VERSION"

docker run -d \
  --name django-app \
  --restart always \
  -p 8000:8000 \
  --env APP_VERSION="$APP_VERSION" \
  "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO:$APP_VERSION"
