pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-jenkins-credentials') // The ID of your credentials
        AWS_SECRET_ACCESS_KEY = credentials('aws-jenkins-credentials')
    }
    stages {
        stage('Checkout Git Repo') {
            steps {
                script {
                    // Checkout the Git repository containing your Terraform and Ansible files
                    git 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'  // Replace with your Git repository URL
                }
            }
        }
        stage('Terraform Init') {
            steps {
                script {
                    // Initialize Terraform
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                script {
                    // Run Terraform plan to see what changes will be applied
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                script {
                    // Apply the Terraform plan
                    sh 'terraform apply "tfplan"'
                }
            }
        }
        stage('Ansible Playbook') {
            steps {
                script {
                    // Grab the EC2 instance public IP from Terraform output
                    def ec2_ip = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    
                    // Run Ansible Playbook
                    sh "ansible-playbook -i ${ec2_ip}, -u ec2-user --private-key /path/to/your/private/key.pem install_apache.yml"
                }
            }
        }
    }
    post {
        success {
            // Send email on success
            emailext(
                to: 'ramyashridharmoger@gmail.com',  // Replace with your Gmail address
                subject: "Pipeline Success: ${currentBuild.fullDisplayName}",
                body: """
                    The pipeline ran successfully!

                    Build details:
                    - Build: ${currentBuild.fullDisplayName}
                    - Status: Success
                    - Git Commit: ${env.GIT_COMMIT}
                    - URL: ${env.BUILD_URL}
                    
                    The infrastructure was successfully provisioned, and the Apache web server is up and running on your EC2 instance.
                """
            )
        }
        failure {
            // Send email on failure
            emailext(
                to: 'ramyashridharmoger@gmail.com',  // Replace with your Gmail address
                subject: "Pipeline Failure: ${currentBuild.fullDisplayName}",
                body: """
                    The pipeline has failed!

                    Build details:
                    - Build: ${currentBuild.fullDisplayName}
                    - Status: Failure
                    - Git Commit: ${env.GIT_COMMIT}
                    - URL: ${env.BUILD_URL}

                    Please check the build logs for more details and troubleshoot.
                """
            )
        }
    }
}
