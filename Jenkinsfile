def branchName     = params.BranchName ?: "main"
def gitUrl         = "git@github.com:malikalaja/Html.git"
def gitUrlCode     = "git@github.com:malikalaja/Html.git"
def serviceName    = "html"
def EnvName        = "preprod"
def registryId     = "727245885999.dkr.ecr.ap-south-1.amazonaws.com"
def awsRegion      = "ap-south-1"
def ecrUrl         = "${registryId}/${serviceName}"
def dockerfile     = "Dockerfile"
def imageTag       = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL     = "https://argocd.preprod.slashtec.com"
def helmDir = "helm"

pipeline {
    agent any
    
    stages {
        stage ("Get the app code") {
            steps {
                checkout([$class: 'GitSCM',
                  branches: [[name: "${branchName}"]],
                  extensions: [[$class: 'LocalBranch', localBranch: "${branchName}"]],
                  userRemoteConfigs: [[url: "${gitUrlCode}", credentialsId: "GITHUB_CREDS_ID"]]
                ])
                echo "Code checked out successfully"
            }
        }
        
        stage('login to ecr') {
            steps {
                sh("aws ecr get-login-password --region ${awsRegion}  | docker login --username AWS --password-stdin ${registryId}")
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh("docker build -t ${ecrUrl}:${imageTag} -f ${dockerfile} .")
            }
        }
        
        stage('Push Docker Image To ECR') {
            steps {
                sh("docker push ${ecrUrl}:${imageTag}")
            }
        }
        
        stage('Clean docker images') {
            steps {
                sh("docker rmi -f ${ecrUrl}:${imageTag} || :")
            }
        }
        
        stage ("Deploy to Environment") {
            steps {
                script {
                    sh ("cd ${helmDir}; yq eval -i '.image.repository = \"${ecrUrl}\"' values.yaml")
                    sh ("cd ${helmDir}; yq eval -i '.image.tag = \"${imageTag}\"' values.yaml ; cat values.yaml")
                    sh ("cd ${helmDir}; git config user.email 'jenkins@local'")
                    sh ("cd ${helmDir}; git config user.name 'Jenkins'")
                    sh ("cd ${helmDir}; git fetch origin ${branchName}")
                    sh ("cd ${helmDir}; git checkout ${branchName} || true")
                    sh ("cd ${helmDir}; git pull origin ${branchName}")
                    sh ("cd ${helmDir}; git add values.yaml")
                    sh ("cd ${helmDir}; git commit -m 'update image tag ${imageTag}' || true")
                    sh ("cd ${helmDir}; git push origin ${branchName}")
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
    }
}
