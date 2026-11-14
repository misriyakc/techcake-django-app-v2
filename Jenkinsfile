pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '900360460976.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'djangov2'
        APP_INSTANCE_ID = 'i-032515684cf2635c7'
        HEALTH_URL = 'https://djangov2.tc-2026-0055.nixlabs.in/health'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh 'python3 -m compileall -q .'
                sh 'docker --version'
            }
        }

        stage('Build') {
            steps {
                sh '''
                    docker build \
                      --build-arg APP_VERSION="$GIT_COMMIT" \
                      -t "$ECR_REGISTRY/$ECR_REPOSITORY:$GIT_COMMIT" .
                '''
            }
        }

        stage('Scan') {
            steps {
                sh '''
                    trivy image \
                      --format json \
                      --output trivy-results.json \
                      --severity CRITICAL,HIGH \
                      --exit-code 0 \
                      "$ECR_REGISTRY/$ECR_REPOSITORY:$GIT_COMMIT"

                    trivy image \
                      --severity CRITICAL \
                      --exit-code 1 \
                      "$ECR_REGISTRY/$ECR_REPOSITORY:$GIT_COMMIT"
                '''
            }
        }

        stage('Push') {
            steps {
                sh '''
                    aws ecr get-login-password --region "$AWS_REGION" |
                    docker login --username AWS --password-stdin "$ECR_REGISTRY"

                    docker push "$ECR_REGISTRY/$ECR_REPOSITORY:$GIT_COMMIT"
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    REMOTE_SCRIPT=$(cat <<'REMOTE'
set -e
cd /opt/techcake-django-app-v2

PREVIOUS_SHA=$(cat .last_working_sha 2>/dev/null || echo v2)

aws ecr get-login-password --region ap-south-1 |
docker login --username AWS --password-stdin 900360460976.dkr.ecr.ap-south-1.amazonaws.com

deploy() {
    export APP_VERSION="$1"
    docker compose pull
    docker compose up -d
}

if deploy "$NEW_SHA"; then
    for i in $(seq 1 12); do
        if curl -fsS "$HEALTH_URL" |
           python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("status")=="ok" and d.get("sha")==sys.argv[1] else 1)' "$NEW_SHA"; then
            echo "$NEW_SHA" > .last_working_sha
            echo "DEPLOYMENT SUCCESSFUL"
            exit 0
        fi
        sleep 10
    done
fi

echo "DEPLOYMENT FAILED. Starting rollback to $PREVIOUS_SHA"
deploy "$PREVIOUS_SHA"
echo "ROLLBACK COMPLETED: $PREVIOUS_SHA"
exit 1
REMOTE
)

                    REMOTE_SCRIPT="NEW_SHA=$GIT_COMMIT
HEALTH_URL=$HEALTH_URL
$REMOTE_SCRIPT"

                    PARAMS=$(python3 -c 'import json,sys; print(json.dumps({"commands":[sys.stdin.read()]}))' <<< "$REMOTE_SCRIPT")

                    COMMAND_ID=$(aws ssm send-command \
                      --instance-ids "$APP_INSTANCE_ID" \
                      --document-name "AWS-RunShellScript" \
                      --parameters "$PARAMS" \
                      --query "Command.CommandId" \
                      --output text)

                    for i in $(seq 1 60); do
                        STATUS=$(aws ssm get-command-invocation \
                          --command-id "$COMMAND_ID" \
                          --instance-id "$APP_INSTANCE_ID" \
                          --query "Status" \
                          --output text 2>/dev/null || true)

                        if [ "$STATUS" = "Success" ]; then
                            exit 0
                        fi

                        if [ "$STATUS" = "Failed" ] || [ "$STATUS" = "TimedOut" ] || [ "$STATUS" = "Cancelled" ]; then
                            echo "Deployment failed: $STATUS"
                            exit 1
                        fi

                        sleep 5
                    done

                    echo "Deployment timed out"
                    exit 1
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    curl -fsS "$HEALTH_URL" |
                    python3 -c 'import json,sys; d=json.load(sys.stdin); print(d); sys.exit(0 if d.get("status")=="ok" and d.get("sha")==sys.argv[1] else 1)' "$GIT_COMMIT"
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-results.json',
                             allowEmptyArchive: true
        }
    }
}
