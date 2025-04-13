pipeline {
    agent any
    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'         // Path to PEM file
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'  // Your repo
        AWS_REGION = 'eu-north-1'
        TFE_IP = '16.170.246.135'                               // Terraform EC2 IP
        REMOTE_PEM_PATH = '/home/ubuntu/my-sample-app.pem'       // Destination path in remote EC2
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

        stage('Run Terraform & Ansible from Remote') {
            steps {
                script {
                    // Set the correct permissions for the PEM file locally
                    sh "chmod 400 ${PEM_PATH}"

                    // Check if the PEM file already exists on the remote EC2 instance
                    def fileExistsCheck = sh(script: "ssh -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@${TFE_IP} 'test -f ${REMOTE_PEM_PATH} && echo true || echo false'", returnStdout: true).trim()

                    if (fileExistsCheck == "false") {
                        // If PEM doesn't exist, copy it to the remote EC2
                        sh """
                            echo "📤 Copying PEM file to Terraform EC2"
                            scp -o StrictHostKeyChecking=no -i ${PEM_PATH} ${PEM_PATH} ubuntu@${TFE_IP}:${REMOTE_PEM_PATH}
                        """
                    } else {
                        echo "✅ PEM file already exists on the remote EC2. Skipping file copy."
                    }

                    // SSH into the Terraform EC2 and execute Terraform and Ansible commands
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
                          --private-key ${REMOTE_PEM_PATH} \
                          --ssh-extra-args="-o StrictHostKeyChecking=no" \
                          install_apache.yml

                        echo "🌐 Verifying Apache"
                        curl http://\$EC2_IP
                    EOF
                """
                    // Execute the SSH command to run Terraform and Ansible
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
