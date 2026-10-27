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
                script {
                    if (isUnix()) {
                        sh 'mvn -B clean verify'
                    } else {
                        bat 'mvn -B clean verify'
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }

        stage('Build and push Docker image') {
            when {
                expression {
                    def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: ''
                    branchName = branchName.replaceFirst(/^(origin\/|\*\/)/, '')
                    branchName in ['main', 'master']
                }
            }
            steps {
                script {
                    if (!params.GHCR_OWNER?.trim()) {
                        error('Set the GHCR_OWNER build parameter before publishing the image.')
                    }

                    def imageName = "ghcr.io/${params.GHCR_OWNER.trim().toLowerCase()}/onlinebookstore"
                    def imageTag = env.GIT_COMMIT ? env.GIT_COMMIT.take(12) : env.BUILD_NUMBER

                    withEnv([
                        "IMAGE_NAME=${imageName}",
                        "IMAGE_TAG=${imageTag}",
                        "IMAGE_TAGGED=${imageName}:${imageTag}",
                        "IMAGE_LATEST=${imageName}:latest"
                    ]) {
                        withCredentials([usernamePassword(
                            credentialsId: 'ghcr-credentials',
                            usernameVariable: 'GHCR_USERNAME',
                            passwordVariable: 'GHCR_PASSWORD'
                        )]) {
                            if (isUnix()) {
                                sh '''
                                    set -eu
                                    trap 'docker logout ghcr.io >/dev/null 2>&1 || true' EXIT
                                    printf '%s' "$GHCR_PASSWORD" | docker login ghcr.io \
                                        --username "$GHCR_USERNAME" --password-stdin
                                    docker build --tag "$IMAGE_TAGGED" --tag "$IMAGE_LATEST" .
                                    docker push "$IMAGE_TAGGED"
                                    docker push "$IMAGE_LATEST"
                                '''
                            } else {
                                bat '''
                                    @echo off
                                    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; try { $env:GHCR_PASSWORD | docker login ghcr.io --username $env:GHCR_USERNAME --password-stdin; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; docker build --tag $env:IMAGE_TAGGED --tag $env:IMAGE_LATEST .; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; docker push $env:IMAGE_TAGGED; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; docker push $env:IMAGE_LATEST; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } } finally { docker logout ghcr.io 2>$null }"
                                '''
                            }
                        }
                    }
                }
            }
        }
    }
}
