pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        // Uncomment this if you're using session tokens:
        // AWS_SESSION_TOKEN     = credentials('aws-session-token')
    }

    stages {
        stage('Clone Repo') {
            steps {
                git url: 'https://github.com/your-username/your-repo.git', branch: 'main'
            }
        }

        stage('Terraform Init') {
            dir('terraform') {
                steps {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            dir('terraform') {
                steps {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            dir('terraform') {
                steps {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}
