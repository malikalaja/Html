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
def clientId = "${applicationName}-${envName}"
def latestTagValue = params.Tag
def namespace = "preprod"
def helmDir = "helm"
def slashtecDir = "slashtec/Html"   // <-- path fixed

node {
  try {
    stage('cleanup') {
      cleanWs()
    }

    stage ("Get the app code") {
      checkout([$class: 'GitSCM',
        branches: [[name: "${branchName}"]],
        extensions: [],
        userRemoteConfigs: [[ url: "${gitUrlCode}" ]]
      ])

      // clone into a workspace-relative folder (no absolute ~/ paths)
      sh "rm -rf slashtec"
      sh "mkdir -p slashtec && cd slashtec && git clone -b ${branchName} ${gitUrl}"

      // copy from the cloned repo path
      sh "cp ${slashtecDir}/Dockerfile ${dockerfile}"
      sh "cp -r ${slashtecDir}/files/* ."
      sh "cp ${slashtecDir}/index.html ."
    }

    stage("Get the env variables from App") {
      sh "aws appconfig get-configuration --application ${applicationName} --environment ${envName} --configuration ${configName} --client-id ${clientId} .env --region ${awsRegion}"
    }

    stage('login to ecr') {
      sh "aws ecr get-login-password --region ${awsRegion} | docker login --username AWS --password-stdin ${ecrUrl}"
    }

    stage('Build Docker Image') {
      sh "docker build -t ${ecrUrl}/${serviceName}:${imageTag} -f ${dockerfile} ."
    }

    stage('Push Docker Image To ECR') {
      sh "docker push ${ecrUrl}/${serviceName}:${imageTag}"
    }

    stage('Clean docker images') {
      sh "docker rmi -f ${ecrUrl}/${serviceName}:${imageTag} || :"
    }

    stage ("Deploy ${serviceName} to ${EnvName} Environment") {
      // use the same cloned repo path for helm edits
      sh "cd ${slashtecDir}/${helmDir}; pathEnv=\"value.image.tag\" valueEnv=\"${imageTag}\" yq 'eval(strenv(pathEnv)) = strenv(valueEnv)' -i values.yaml ; cat values.yaml"
      sh "cd ${slashtecDir}/${helmDir}; git pull ; git add values.yaml; git commit -m 'update image tag' ; git push ${gitUrl}"
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    echo "Pipeline failed: ${e.getMessage()}"
    throw e
  }
}
