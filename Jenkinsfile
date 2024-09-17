pipeline {
    agent any

    environment {
        // Referencing Jenkins credentials using withCredentials block
        AZURE_CLIENT_ID         = credentials('azure-client-id')
        AZURE_CLIENT_SECRET     = credentials('azure-client-secret')
        AZURE_TENANT_ID         = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID   = credentials('azure-subscription-id')
    }

    stages {

        stage('Login to Azure') {
            steps {
                script {
                    // Log in to Azure using the retrieved Service Principal credentials
                    sh 'az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID'

                    // Set the correct subscription
                    sh 'az account set --subscription $AZURE_SUBSCRIPTION_ID'
                }
            }
        }

        stage('Retrieve AKS Credentials') {
            steps {
                script {
                    // Retrieve AKS credentials and configure kubectl
                    sh 'az aks get-credentials --resource-group Peter-Candidate --name regular-cod-aks --admin --overwrite-existing'
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                script {
                    // Deploy the application to AKS
                    sh 'kubectl apply -f k8s_files/deployment.yaml'
                    sh 'kubectl apply -f k8s_files/service.yaml'
                    sh 'kubectl apply -f k8s_files/ingress.yaml'
                }
            }
        }
    }

    post {
        always {
            // Clean up
            cleanWs()
        }
    }
}
