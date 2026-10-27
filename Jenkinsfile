pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        string(
            name: 'GHCR_OWNER',
            defaultValue: '',
            description: 'GitHub username or organization that owns the GHCR image (required on main/master)'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and test') {
            steps {
                sh 'mvn -B clean verify'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }

        stage('Build and push Docker image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                script {
                    if (!params.GHCR_OWNER?.trim()) {
                        error('Set the GHCR_OWNER build parameter before publishing the image.')
                    }

                    def imageName = "ghcr.io/${params.GHCR_OWNER.trim().toLowerCase()}/onlinebookstore"
                    def imageTag = env.GIT_COMMIT ? env.GIT_COMMIT.take(12) : env.BUILD_NUMBER

                    withEnv(["IMAGE_NAME=${imageName}", "IMAGE_TAG=${imageTag}"]) {
                        withCredentials([usernamePassword(
                            credentialsId: 'ghcr-credentials',
                            usernameVariable: 'GHCR_USERNAME',
                            passwordVariable: 'GHCR_PASSWORD'
                        )]) {
                            sh '''
                                set -eu
                                trap 'docker logout ghcr.io >/dev/null 2>&1 || true' EXIT
                                printf '%s' "$GHCR_PASSWORD" | docker login ghcr.io \
                                    --username "$GHCR_USERNAME" --password-stdin
                                docker build \
                                    --tag "$IMAGE_NAME:$IMAGE_TAG" \
                                    --tag "$IMAGE_NAME:latest" .
                                docker push "$IMAGE_NAME:$IMAGE_TAG"
                                docker push "$IMAGE_NAME:latest"
                            '''
                        }
                    }
                }
            }
        }
    }
}
