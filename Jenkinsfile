pipeline {
    agent any
    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'  // Path to your PEM file
        REMOTE_IP = '16.170.246.135'                     // Your remote EC2 IP
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'  // GitHub repo URL
        AWS_REGION = 'eu-north-1'                        // AWS Region
    }

    triggers {
        githubPush()  // Trigger on GitHub push
    }

    stages {
        stage('Checkout Code (for logs only)') {
            steps {
                deleteDir()  // Clean workspace
                git branch: 'main', url: GITHUB_REPO  // Checkout GitHub repository
                sh 'echo "✅ Checked out code (for Jenkins logs only)!"'
            }
        }

        stage('Remote Terraform & Ansible Execution') {
            steps {
                script {
                    // Ensure proper permissions for the PEM file
                    sh '''
                    sudo su - jenkins -c "chmod 400 ${PEM_PATH}"
                    sudo su - jenkins -c "echo '✅ Permissions set for the PEM file'"
                    '''

                    def sshCommand = """
                    ssh -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@${REMOTE_IP} << 'EOF'
                        set -e
                        echo "✅ Connected to Terraform EC2"

                        # Clone or pull the repo
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
                        ansible-playbook -i "\$EC2_IP," -u ec2-user --private-key ${PEM_PATH} install_apache.yml

                        echo "🌐 Verifying Apache"
                        curl http://\$EC2_IP
                    EOF
                    """
                    sh sshCommand  // Execute the SSH command
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
