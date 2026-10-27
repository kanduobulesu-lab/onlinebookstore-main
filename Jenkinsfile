pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate project files') {
            steps {
                script {
                    def requiredFiles = [
                        'pom.xml',
                        'WebContent/WEB-INF/web.xml',
                        'OnlineBookStore/servlets/UserLoginServlet.java'
                    ]
                    def missingFiles = requiredFiles.findAll { !fileExists(it) }

                    if (missingFiles) {
                        error("Required project files are missing: ${missingFiles.join(', ')}")
                    }

                    echo 'Project structure validation passed.'
                }
            }
        }
    }
}
