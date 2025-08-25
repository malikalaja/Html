def branchName     = params.BranchName ?: "main"
def gitUrl         = "git@github.com:malikalaja/Html.git"
def gitUrlCode     = "git@github.com:malikalaja/Html.git"
def serviceName    = "htmltask"
def EnvName        = "preprod"
def registryId     = "727245885999"
def awsRegion      = "ap-south-1"
def ecrUrl         = "727245885999.dkr.ecr.ap-south-1.amazonaws.com"
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
def helmDir = "/helm"
def slashtecDir = "slashtec/slashtec/${envName}/${applicationName}"

node {
  try {
    stage('cleanup') {
      cleanWs()
    }
    
    stage ("Get the app code") {
      checkout([$class: 'GitSCM', branches: [[name: "${branchName}"]] , extensions: [], userRemoteConfigs: [[ url: "${gitUrlCode}"]]])
      sh "rm -rf ~/workspace/\"${JOB_NAME}\"/slashtec"
      sh "mkdir ~/workspace/\"${JOB_NAME}\"/slashtec  ; cd slashtec ; git clone -b main ${gitUrl} "
      sh("cp ${slashtecDir}/Dockerfile ${dockerfile}")
      sh("cp -r  ${slashtecDir}/docker/* .")
      sh("cp -r  ${slashtecDir}/files/* .")
    }
    
    stage("Get the env variables from App") {
      sh "aws appconfig get-configuration --application ${applicationName} --environment ${envName} --configuration ${configName} --client-id ${clientId} .env --region ${awsRegion}"
    }
    
    stage('login to ecr') {
      sh("aws ecr get-login-password --region ${awsRegion}  | docker login --username AWS --password-stdin ${ecrUrl}")
    }
    
    stage('Build Docker Image') {
      sh("docker build -t ${ecrUrl}/${serviceName}:${imageTag} -f ${dockerfile} .")
    }
    
    stage('Push Docker Image To ECR') {
      sh("docker push ${ecrUrl}/${serviceName}:${imageTag}")
    }
    
    stage('Clean docker images') {
      sh("docker rmi -f ${ecrUrl}/${serviceName}:${imageTag} || :")
    }
    
    stage ("Deploy ${serviceName} to ${EnvName} Environment") {
      sh("cd Html/${helmDir}; pathEnv=\"value.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml")
      sh("cd Html/${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ;git push ${gitUrl}")
    }
    
  } catch (e) {
    currentBuild.result = "FAILED"
    echo "Pipeline failed: ${e.getMessage()}"
    throw e
  }
}