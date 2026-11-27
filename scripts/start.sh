
#!/bin/bash
set -e

REGION="ap-south-1"
ACCOUNT="900360460976"
REPO="djangov2"
ENV_FILE="/tmp/django-app.env"

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

echo "$PARAMS" | jq -r '
  .Parameters[]
  | select(.Name != "/techcake/app/APP_VERSION")
  | "\(.Name | sub("/techcake/app/"; ""))=\(.Value)"
' > "$ENV_FILE"

docker run -d \
  --name django-app \
  --restart always \
  -p 8000:8000 \
  --env-file "$ENV_FILE" \
  "$IMAGE"
