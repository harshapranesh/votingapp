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
        IMAGE_TAG = ""
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build (Parallel)') {
            parallel {

                stage('Vote') {
                    steps {
                        sh '''
                            docker build -t $DOCKERHUB_REPO/voting-app-vote:$IMAGE_TAG ./vote
                        '''
                    }
                }

                stage('Result') {
                    steps {
                        sh '''
                            docker build -t $DOCKERHUB_REPO/voting-app-result:$IMAGE_TAG ./result
                        '''
                    }
                }

                stage('Worker') {
                    steps {
                        sh '''
                            docker build -t $DOCKERHUB_REPO/voting-app-worker:$IMAGE_TAG ./worker
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

        stage('Unit Tests') {
            steps {
                sh '''
                    chmod +x ./result/tests/tests.sh
                    ./result/tests/tests.sh || true
                '''
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh '''
                    mkdir -p reports

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v $(pwd)/reports:/reports \
                      aquasec/trivy image \
                      --severity HIGH,CRITICAL \
                      --format table \
                      $DOCKERHUB_REPO/voting-app-vote:$IMAGE_TAG || true
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

                        docker push $DOCKERHUB_REPO/voting-app-vote:$IMAGE_TAG
                        docker push $DOCKERHUB_REPO/voting-app-result:$IMAGE_TAG
                        docker push $DOCKERHUB_REPO/voting-app-worker:$IMAGE_TAG
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
        always {
            archiveArtifacts artifacts: 'reports/**/*', allowEmptyArchive: true
        }

        success {
            echo "✅ Build successful"
        }

        failure {
            echo "❌ Build failed"
        }
    }
}