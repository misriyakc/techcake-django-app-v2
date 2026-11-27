#!/bin/bash
set -e

REGION="ap-south-1"
ACCOUNT="900360460976"
REPO="djangov2"

PARAMS=$(aws ssm get-parameters-by-path \
  --path "/techcake/app/" \
  --with-decryption \
  --region "$REGION" \
  --output json)

APP_VERSION=$(echo "$PARAMS" | jq -r '.Parameters[] | select(.Name == "/techcake/app/APP_VERSION") | .Value')

docker stop django-app || true
docker rm django-app || true

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin \
    "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

docker pull "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO:$APP_VERSION"

ENV_ARGS=$(echo "$PARAMS" | jq -r '.Parameters[] | " --env " + (.Name | sub("/techcake/app/"; "")) + "=" + .Value' | tr '\n' ' ')

docker run -d \
  --name django-app \
  --restart always \
  -p 8000:8000 \
  $ENV_ARGS \
  "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO:$APP_VERSION"
