pipeline {
    agent any
    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'
        AWS_REGION = 'eu-north-1'
        TFE_IP = '16.170.246.135'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Code (for logs only)') {
            steps {
                deleteDir()
                git branch: 'main', url: GITHUB_REPO
                sh 'echo "✅ Checked out code (for Jenkins logs only)!"'
            }
        }

        stage('Run Terraform & Ansible from Remote') {
            steps {
                script {
                    sh "chmod 400 ${PEM_PATH}"

                    def sshCommand = """
                    ssh -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@${TFE_IP} << 'EOF'
                        set -e
                        echo "✅ Connected to Terraform EC2"

                        if [ ! -d my-tfe-ansible ]; then
                            git clone ${GITHUB_REPO}
                        fi

                        cd my-tfe-ansible
                        git pull origin main

                        echo "🧱 Running Terraform"
                        terraform init -input=false
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan

                        echo "📦 Running Ansible"
                        EC2_IP=\$(terraform output -raw instance_public_ip)
                        echo "Target EC2 IP: \$EC2_IP"

                        ansible-playbook -i "\$EC2_IP," -u ec2-user \
                          --private-key ~/my-sample-app.pem \
                          --ssh-extra-args="-o StrictHostKeyChecking=no" \
                          install_apache.yml

                        echo "🌐 Verifying Apache"
                        curl http://\$EC2_IP
                    EOF
                    """
                    sh sshCommand
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
