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
                    ./run-static-checks.sh
                """
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh """
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image --severity HIGH,CRITICAL --exit-code 1 --format table \
                      $DOCKERHUB_REPO/voting-app-vote:latest

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image --severity HIGH,CRITICAL --exit-code 1 --format table \
                      $DOCKERHUB_REPO/voting-app-result:latest
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy image --severity HIGH,CRITICAL --exit-code 1 --format table \
                      $DOCKERHUB_REPO/voting-app-worker:latest
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

        stage('Sync deploy files to EC2') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 '
                            mkdir -p /opt/voting/nginx &&
                            mkdir -p /opt/voting/scripts
                        '

                        scp -o StrictHostKeyChecking=no opt/voting/docker-compose.blue.yml ubuntu@98.89.185.95:/opt/voting/
                        scp -o StrictHostKeyChecking=no opt/voting/docker-compose.green.yml ubuntu@98.89.185.95:/opt/voting/
                        scp -o StrictHostKeyChecking=no opt/voting/active_color ubuntu@98.89.185.95:/opt/voting/
                        scp -o StrictHostKeyChecking=no opt/voting/nginx/blue.conf ubuntu@98.89.185.95:/opt/voting/nginx/
                        scp -o StrictHostKeyChecking=no opt/voting/nginx/green.conf ubuntu@98.89.185.95:/opt/voting/nginx/
                        scp -o StrictHostKeyChecking=no opt/voting/scripts/smoke_test.sh ubuntu@98.89.185.95:/opt/voting/scripts/
                        scp -o StrictHostKeyChecking=no opt/voting/scripts/switch_to_blue.sh ubuntu@98.89.185.95:/opt/voting/scripts/
                        scp -o StrictHostKeyChecking=no opt/voting/scripts/switch_to_green.sh ubuntu@98.89.185.95:/opt/voting/scripts/

                        ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 '
                            chmod +x /opt/voting/scripts/*.sh
                        '
                    """
                }
            }
        }

        stage('Detect Active Color') {
            steps {
                sshagent(['ec2-ssh']) {
                    script {
                        env.ACTIVE_COLOR = sh(
                            script: "ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 'cat /opt/voting/active_color || echo blue'",
                            returnStdout: true
                        ).trim()

                        env.INACTIVE_COLOR = env.ACTIVE_COLOR == 'blue' ? 'green' : 'blue'
                        echo "Active: ${env.ACTIVE_COLOR}, Inactive: ${env.INACTIVE_COLOR}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 '
                            cd /opt/voting &&
                            docker compose -f docker-compose.${INACTIVE_COLOR}.yml pull &&
                            docker compose -f docker-compose.${INACTIVE_COLOR}.yml up -d
                        '
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 '
                            /opt/voting/scripts/smoke_test.sh ${INACTIVE_COLOR}
                        '
                    """
                }
            }
        }

        stage('Switch Traffic') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 '
                            /opt/voting/scripts/switch_to_${INACTIVE_COLOR}.sh &&
                            echo ${INACTIVE_COLOR} > /opt/voting/active_color
                        '
                    """
                }
            }
        }

        post {
            failure {
                sshagent(['ec2-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@98.89.185.95 "
                            /opt/voting/scripts/switch_to_${ACTIVE_COLOR}.sh || true
                        "
                    '''
                }
                echo "Build failed"
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
