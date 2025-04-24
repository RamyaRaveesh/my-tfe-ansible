pipeline {
    agent any

    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'                  // Local PEM file
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'
        AWS_REGION = 'eu-north-1'
        TFE_IP = '51.20.64.125'  // Terraform EC2 instance
        REMOTE_PEM_PATH = '/home/ubuntu/my-sample-app.pem'              // Remote PEM location
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

                    def fileExistsCheck = sh(
                        script: "ssh -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@${TFE_IP} 'test -f ${REMOTE_PEM_PATH} && echo true || echo false'",
                        returnStdout: true
                    ).trim()

                    if (fileExistsCheck == "false") {
                        sh """
                            echo "📤 Copying PEM file to Terraform EC2"
                            scp -o StrictHostKeyChecking=no -i ${PEM_PATH} ${PEM_PATH} ubuntu@${TFE_IP}:${REMOTE_PEM_PATH}
                        """
                    } else {
                        echo "✅ PEM file already exists on the remote EC2. Skipping file copy."
                    }

                    // Directly run SSH + heredoc with properly aligned EOF
                    sh """#!/bin/bash
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

  ansible-playbook -i "\$EC2_IP," -u ec2-user \\
    --private-key ${REMOTE_PEM_PATH} \\
    --ssh-extra-args="-o StrictHostKeyChecking=no" \\
    install_apache.yml

  echo "🌐 Apache installed. Now performing security scan with ZAP."

  # Run OWASP ZAP Security Scan
  ssh -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@${TFE_IP} << 'EOF2'
  # Assuming OWASP ZAP is installed and set up on the EC2 instance
  curl -X GET "http://localhost:8080/JSON/ascan/action/scan/?url=http://\$EC2_IP" -H "accept: application/json"
  EOF2

  echo "🌐 Verifying Apache"
  curl http://\$EC2_IP
EOF
"""
                }
            }
        }
        stage('Run Trivy Scan') {
            steps {
                script {
                    echo "🔎 Running Trivy Scan from Jenkins EC2"
                    // Scan the Jenkins workspace or a relevant directory
                    sh """
                        trivy fs --severity HIGH,CRITICAL . > trivy_report.txt
                    """
                }
            }
        }
    }
    post {
        always {
            script {
                // Copy ZAP report from the remote EC2 (TFE instance)
                sh "scp -o StrictHostKeyChecking=no -i ${PEM_PATH} ubuntu@${TFE_IP}:/home/ubuntu/my-tfe-ansible/zap_report.html . || true"

                // Send both reports by email
                emailext (
                    subject: "Jenkins Build + Security Scan Reports",
                    body: """
                    <h3>Build Status: ${currentBuild.currentResult}</h3>
                    <p>Attached are the Trivy (local) and ZAP (remote) security scan reports.</p>
                    """,
                    attachmentsPattern: 'zap_report.html,trivy_report.txt',
                    to: 'ramyashridharmoger@gmail.com'
                )
            }
        }
    }
}
