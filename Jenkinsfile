pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
    }

    environment {
        DOCKERHUB_REPO = "khanbibi"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build (Parallel)') {
            parallel {

                stage('Vote') {
                    steps {
                        sh """
                            docker build -t $DOCKERHUB_REPO/voting-app-vote:latest ./vote
                            docker tag $DOCKERHUB_REPO/voting-app-vote:latest $DOCKERHUB_REPO/voting-app-vote:$IMAGE_TAG
                        """
                    }
                }

                stage('Result') {
                    steps {
                        sh """
                            docker build -t $DOCKERHUB_REPO/voting-app-result:latest ./result
                            docker tag $DOCKERHUB_REPO/voting-app-result:latest $DOCKERHUB_REPO/voting-app-result:$IMAGE_TAG
                        """
                    }
                }

                stage('Worker') {
                    steps {
                        sh """
                            docker build -t $DOCKERHUB_REPO/voting-app-worker:latest ./worker
                            docker tag $DOCKERHUB_REPO/voting-app-worker:latest $DOCKERHUB_REPO/voting-app-worker:$IMAGE_TAG
                        """
                    }
                }
            }
        }

        stage('Unit Tests (Health Check)') {
            steps {
                sh """
                    docker rm -f vote-test || true
                    docker ps -q --filter publish=5000 | xargs -r docker rm -f || true
                    docker run -d --name vote-test -p 5000:80 $DOCKERHUB_REPO/voting-app-vote:latest

                    sleep 5

                    if ! docker exec vote-test curl -f http://localhost:80; then
                        echo "Health check failed!"
                        docker stop vote-test || true
                        docker rm vote-test || true
                        exit 1
                    fi

                    docker stop vote-test || true
                    docker rm vote-test || true
                """
            }
        }

        stage('Static Code Checks') {
            steps {
                sh """
                    chmod +x ./run-static-checks.sh
                    ./run-static-checks.sh || true
                """
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh """
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image --severity HIGH,CRITICAL --format table \
                      $DOCKERHUB_REPO/voting-app-vote:latest || true

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image --severity HIGH,CRITICAL --format table \
                      $DOCKERHUB_REPO/voting-app-result:latest || true

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image --severity HIGH,CRITICAL --format table \
                      $DOCKERHUB_REPO/voting-app-worker:latest || true
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

                        docker push $DOCKERHUB_REPO/voting-app-vote:latest
                        docker push $DOCKERHUB_REPO/voting-app-vote:$IMAGE_TAG

                        docker push $DOCKERHUB_REPO/voting-app-result:latest
                        docker push $DOCKERHUB_REPO/voting-app-result:$IMAGE_TAG

                        docker push $DOCKERHUB_REPO/voting-app-worker:latest
                        docker push $DOCKERHUB_REPO/voting-app-worker:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Manual Approval (Prod Only)') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                input message: "Approve deployment to PRODUCTION?"
            }
        }

        stage('Release Tag') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                        git config user.email "jenkins@example.com"
                        git config user.name "jenkins"

                        git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@github.com/VladyslavZakharov/example-voting-app_jenkins.git

                        git tag -a v${BUILD_NUMBER} -m "Release v${BUILD_NUMBER}"
                        git push origin v${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Show Environment') {
            steps {
                echo "Selected environment: ${params.ENVIRONMENT}"
            }
        }
    }

    post {
        success {
            echo "Build successful"
        }
        failure {
            echo "Build failed"
        }
    }
}
