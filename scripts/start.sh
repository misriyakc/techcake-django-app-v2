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

IMAGE="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$REPO:$APP_VERSION"

docker stop django-app || true
docker rm django-app || true

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin \
    "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

docker pull "$IMAGE"

ENV_ARGS=()

while IFS= read -r PARAM; do
  NAME=$(echo "$PARAM" | jq -r '.Name | sub("/techcake/app/"; "")')
  VALUE=$(echo "$PARAM" | jq -r '.Value')

  if [ "$NAME" != "APP_VERSION" ]; then
    ENV_ARGS+=(--env "$NAME=$VALUE")
  fi
done < <(echo "$PARAMS" | jq -c '.Parameters[]')

docker run -d \
  --name django-app \
  --restart always \
  -p 8000:8000 \
  "${ENV_ARGS[@]}" \
  "$IMAGE"
