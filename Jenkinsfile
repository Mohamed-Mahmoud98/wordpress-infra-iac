pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Clone Repo') {
            steps {
                withCredentials([string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN')]) {
                    git url: "https://${GITHUB_TOKEN}@github.com/Mohamed-Mahmoud98/wordpress-infra-iac.git", branch: 'main'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }


        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}
