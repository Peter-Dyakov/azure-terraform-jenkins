pipeline {
    agent any
    
    environment {
        REGISTRY = 'acr2bcloud.azurecr.io/flask-hello-app'
        ACR_LOGIN_SERVER = 'acr2bcloud.azurecr.io'
        TAG = "${BUILD_ID}"
        dockerImage = ''
    } 
    
    stages {
        
        stage('Docker Build') {
            steps {
                script {
                    sh "docker build -t ${REGISTRY}:${TAG} ." 
                }
            }
        }
        
        stage('Upload Image to ACR') {
            steps {   
                script {
                    withCredentials([usernamePassword(credentialsId: 'aksjenkins', usernameVariable: 'USER_NAME', passwordVariable: 'PASSWORD')]) {
                        sh "docker login ${ACR_LOGIN_SERVER} -u $USER_NAME -p $PASSWORD"
                        sh " docker push ${REGISTRY}:${TAG}"
                        }
                    }
            }
        }
        
        stage ('K8S Deploy') {
            steps {
                script {
                    withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'K8S', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                        sh ('helm upgrade --install my-app ./my-app-helm --set image.tag=${TAG}')
                    }
                }
            }
        }
    }
}