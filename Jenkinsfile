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
                        sh '''
                            docker build -t $DOCKERHUB_REPO/voting-app-vote:latest ./vote
                        '''
                    }
                }

                stage('Result') {
                    steps {
                        sh '''
                            docker build -t $DOCKERHUB_REPO/voting-app-result:latest ./result
                        '''
                    }
                }

                stage('Worker') {
                    steps {
                        sh '''
                            docker build -t $DOCKERHUB_REPO/voting-app-worker:latest ./worker
                        '''
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Starting vote container for tests..."

                    docker rm -f vote-test || true
                    docker run -d --name vote-test -p 5000:80 $DOCKERHUB_REPO/voting-app-vote:latest

                    echo "Waiting for container to start..."
                    sleep 10

                    echo "Running tests..."
                    chmod +x ./result/tests/tests.sh
                    ./result/tests/tests.sh || true

                    echo "Stopping container..."
                    docker stop vote-test || true
                    docker rm vote-test || true
                '''
            }
        }

        stage('Static Code Checks') {
            steps {
                sh '''
                    chmod +x ./run-static-checks.sh
                    ./run-static-checks.sh || true
                '''
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh '''
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image \
                      --severity HIGH,CRITICAL \
                      --format table \
                      $DOCKERHUB_REPO/voting-app-vote:latest || true
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

                        docker push $DOCKERHUB_REPO/voting-app-vote:latest
                        docker push $DOCKERHUB_REPO/voting-app-result:latest
                        docker push $DOCKERHUB_REPO/voting-app-worker:latest
                    '''
                }
            }
        }

        stage('Manual Approval (Prod Only)') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                input message: "Deploy to PRODUCTION?"
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
            echo "✅ Build successful"
        }

        failure {
            echo "❌ Build failed"
        }
    }
}