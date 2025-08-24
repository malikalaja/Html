def branchName     = params.BranchName ?: "main"
def gitUrl         = "https://github.com/malikalaja/Html.git"
def gitUrlCode     = "https://github.com/malikalaja/Html.git"
def serviceName    = "htmltask"
def EnvName        = "preprod"
def registryId     = "518962303326.dkr.ecr.ap-south-1.amazonaws.com"
def awsRegion      = "ap-south-1"
def ecrUrl         = "${registryId}/${serviceName}"
def dockerfile     = "Dockerfile"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "https://argocd.preprod.slashtec.com"

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
                sh "cp ${htmltaskDir}/Dockerfile ${dockerfile}"
            }
        }
        
        stage("Get the env variables from App") {
            steps {
                sh "aws appconfig get-configuration --application ${applicationName} --environment ${envName} --configuration ${configName} --client-id ${clientId} .env --region ${awsRegion}"
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
        
        stage ("Deploy ${serviceName} to ${EnvName} Environment") {
            steps {
                sh ("cd Html/${helmDir}; pathEnv=\".deployment.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
                sh ("cd Html/${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
    }
}