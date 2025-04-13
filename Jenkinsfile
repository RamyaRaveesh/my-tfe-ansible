pipeline {
    agent any
    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'
        AWS_REGION = 'eu-north-1'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Code') {
            steps {
                deleteDir()
                git branch: 'main', url: GITHUB_REPO
                sh 'echo "✅ Checked out code!"'
                sh 'pwd && ls -la'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'rm -rf .terraform*'
                sh 'terraform init -input=false'
            }
        }

        stage('Terraform Plan') {
            options { timeout(time: 5, unit: 'MINUTES') }
            steps {
                sh 'echo "Available files:" && ls -la'
                sh 'echo "Starting terraform plan..."'
                sh 'TF_LOG=DEBUG terraform plan -out=tfplan || (echo "Terraform plan failed or hung" && exit 1)'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Ansible Playbook') {
            steps {
                script {
                    def ec2_ip = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    echo "Deploying Apache to EC2 at ${ec2_ip}"
                    sh "ansible-playbook -i ${ec2_ip}, -u ec2-user --private-key ${env.PEM_PATH} install_apache.yml"
                    
                    // Optionally check Apache service
                    sh "curl http://${ec2_ip}/"
                }
            }
        }
    }

    post {
        success {
            emailext(
                to: 'ramyashridharmoger@gmail.com',
                subject: "✅ Pipeline Success: ${currentBuild.fullDisplayName}",
                body: """The pipeline ran successfully!

Build: ${currentBuild.fullDisplayName}
Status: Success
Commit: ${env.GIT_COMMIT}
URL: ${env.BUILD_URL}"""
            )
        }
        failure {
            emailext(
                to: 'ramyashridharmoger@gmail.com',
                subject: "❌ Pipeline Failure: ${currentBuild.fullDisplayName}",
                body: """Pipeline failed!

Build: ${currentBuild.fullDisplayName}
Status: Failure
Commit: ${env.GIT_COMMIT}
URL: ${env.BUILD_URL}"""
            )
        }
    }
}
