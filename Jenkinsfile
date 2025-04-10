pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-jenkins-credentials') // The ID of your credentials
        AWS_SECRET_ACCESS_KEY = credentials('aws-jenkins-credentials')
        PEM_PATH = '/var/lib/jenkins/my-sample-app.pem'  // Path to your private key
        GITHUB_REPO = 'https://github.com/RamyaRaveesh/my-tfe-ansible.git'  // GitHub repository URL
        AWS_REGION = 'us-north-1'
    }
    steps {
    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-credentials']]) {
        sh 'terraform plan -out=tfplan'
    }
}

    triggers {
        githubPush() // This ensures the job triggers on GitHub push events
    }
    stages {
        stage('Checkout Code') {
            steps {
                deleteDir()  // Clean workspace
                sh 'git init'  // Initialize git repository
                git branch: 'main', url: GITHUB_REPO  // Checkout the specified branch (main)
            }
        }
        stage('Terraform Init') {
    steps {
        dir('terraform') { // Adjust if your Terraform files are in a subfolder
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

                    // Use the private key for SSH access to EC2 and run Ansible playbook
                    sh "ansible-playbook -i ${ec2_ip}, -u ec2-user --private-key ${env.PEM_PATH} install_apache.yml"
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
