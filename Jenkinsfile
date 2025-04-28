pipeline {
    agent any

    environment {
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'                  // Local PEM file for Jenkins
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'
        AWS_REGION = 'eu-north-1'
        TFE_IP = '51.20.64.125'  // Terraform EC2 instance (for initial provisioning)
        REMOTE_PEM_PATH = '/home/ubuntu/my-sample-app.pem'              // Remote PEM location on TFE instance
        WEB_SERVER_IP = '13.61.11.249'  // Web Server EC2 (ZAP installed here)
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
            sh """#!/bin/bash
ssh -v -o StrictHostKeyChecking=no -i "${PEM_PATH}" ubuntu@${TFE_IP} << 'EOF'
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

    ansible-playbook -i "${PEM_PATH}" -u ec2-user \\
        --ssh-extra-args="-o StrictHostKeyChecking=no" \\
        install_apache.yml

    echo "🌐 Apache installed."

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
            echo "🔎 Running Trivy Scan on Jenkins Instance"

            // Determine the workspace directory
            def workspaceDir = sh(script: 'pwd', returnStdout: true).trim()

            // Scan Terraform files for misconfigurations (explicitly target .tf files)
            echo "🔍 Scanning Terraform files for misconfigurations"
            sh """
                rm -f trivy_terraform_report.txt # Ensure the report file is clean
                for file in "${workspaceDir}"/*.tf; do
                  if [ -f "\$file" ]; then
                    trivy config --severity HIGH,CRITICAL "\$file" -f table >> trivy_terraform_report.txt
                  fi
                done
            """

            def ansibleScanPath = "${workspaceDir}/install_apache.yml"

            // Run Trivy on Ansible playbook (for generic YAML checks)
            echo "🔍 Scanning Ansible Apache playbook for misconfigurations"
            sh """
                        trivy config --severity HIGH,CRITICAL "${ansibleScanPath}" -f table -o trivy_ansible_report.txt || true
            """

            // If both scans are successful, output the results
            echo "🔍 Trivy scan completed for Terraform and Ansible."
        }
    }
}
    }
    post {
    always {
        script {
            // Send both reports by email
           emailext (
                subject: "Jenkins Build + Trivy Scan Report",
                body: """
                    <h3>Build Status: ${currentBuild.currentResult}</h3>
                    <p>Attached are the Trivy security scan reports for Terraform and Ansible playbook.</p>
                """,
                attachmentsPattern: 'trivy_terraform_report.txt,trivy_ansible_report.txt',
                to: 'ramyashridharmoger@gmail.com'
            )
        }
    }
}

}
