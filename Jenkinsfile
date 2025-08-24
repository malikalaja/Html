def branchName  = params.BranchName ?: "main"
def gitUrl      = "https://github.com/malikalaja/Html.git"
def gitUrlCode  = "https://github.com/malikalaja/Html.git"

def serviceName = "html"                           // <-- match ECR repo name
def EnvName     = "preprod"
def awsRegion   = "ap-south-1"
def registryId  = "727245885999.dkr.ecr.${awsRegion}.amazonaws.com"
def ecrUrl      = "${registryId}/${serviceName}"   // -> 7272…/html
def dockerfile  = "Dockerfile"
def imageTag    = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL  = "https://argocd.preprod.slashtec.com"


// AppConfig Params
def applicationName = "htmltask"
def envName = "preprod"
def configName = "preprod"
// Fix: Use string concatenation, not arithmetic
def clientId = "${applicationName}-${envName}"
def latestTagValue = params.Tag
def namespace = "preprod"
def helmDir = "helm"
def htmltaskDir = "."

pipeline {
    agent any
    
    stages {
        stage ("Get the app code") {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: "${branchName}"]] , extensions: [], userRemoteConfigs: [[ url: "${gitUrlCode}"]]])
                echo "Code checked out successfully"
            }
        }
        
        stage("Get the env variables from App") {
            steps {
                script {
                    try {
                        sh "aws appconfig get-configuration --application ${applicationName} --environment ${envName} --configuration ${configName} --client-id ${clientId} .env --region ${awsRegion}"
                        echo "AppConfig configuration retrieved successfully"
                    } catch (Exception e) {
                        echo "AppConfig configuration not found, continuing without it: ${e.getMessage()}"
                        // Create empty .env file to prevent pipeline failure
                        sh "touch .env"
                        echo "Created empty .env file"
                    }
                }
            }
        }
        
        stage('login to ecr') {
            steps {
                sh("aws ecr get-login-password --region ${awsRegion}  | docker login --username AWS --password-stdin ${ecrUrl}")
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh("docker build -t ${ecrUrl}/${serviceName}:${imageTag} -f ${dockerfile} .")
            }
        }
        
        stage('Push Docker Image To ECR') {
            steps {
                sh("docker push ${ecrUrl}/${serviceName}:${imageTag}")
            }
        }
        
        stage('Clean docker images') {
            steps {
                sh("docker rmi -f ${ecrUrl}/${serviceName}:${imageTag} || :")
            }
        }
        
        stage ("Deploy to Environment") {
            steps {
                sh ("cd ${helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
                sh ("cd ${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
    }
}