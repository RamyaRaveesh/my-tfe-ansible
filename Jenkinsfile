pipeline {
    agent any
    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'  // Path to PEM file
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'  // Your repo
        AWS_REGION = 'eu-north-1'
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

        stage('Remote Terraform & Ansible Execution') {
            steps {
                script {
                    // Ensure proper permissions on the PEM file
                    sh "chmod 400 ${PEM_PATH}"

                    // SSH into the remote Terraform EC2 and perform everything
                    def sshCommand = """
                    ssh -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@your-terraform-ec2-ip << 'EOF'
                        set -e
                        echo "✅ Connected to Terraform EC2"

                        # Clone the repo if not exists
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

                        # Get the EC2 instance IP from Terraform output
                        export EC2_IP=\$(terraform output -raw instance_public_ip)

                        echo "Using EC2_IP: \$EC2_IP"

                        # Run Ansible using EC2_IP
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
