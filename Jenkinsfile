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