def branchName  = params.BranchName ?: "main"
def gitUrl      = "https://github.com/malikalaja/Html.git"
def gitUrlCode  = "https://github.com/malikalaja/Html.git"

def serviceName = "html"                           // matches ECR repo name
def EnvName     = "preprod"
def awsRegion   = "ap-south-1"
def registryId  = "727245885999.dkr.ecr.${awsRegion}.amazonaws.com"
def ecrUrl      = "${registryId}/${serviceName}"   // -> 727245885999.dkr.ecr.ap-south-1.amazonaws.com/html
def dockerfile  = "Dockerfile"
def imageTag    = "${EnvName}-${BUILD_NUMBER}"
def ARGOCD_URL  = "https://argocd.preprod.slashtec.com"

// AppConfig Params
def applicationName = "htmltask"
def envName = "preprod"
def configName = "preprod"
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
        checkout([$class: 'GitSCM',
                  branches: [[name: "${branchName}"]],
                  extensions: [],
                  userRemoteConfigs: [[url: "${gitUrlCode}"]]])
        echo "Code checked out successfully"
      }
    }

    stage("Get the env variables from App") {
      steps {
        script {
          try {
            sh """
              aws appconfig get-configuration \
                --application ${applicationName} \
                --environment ${envName} \
                --configuration ${configName} \
                --client-id ${clientId} .env \
                --region ${awsRegion}
            """
            echo "AppConfig configuration retrieved successfully"
          } catch (Exception e) {
            echo "AppConfig configuration not found, continuing without it: ${e.getMessage()}"
            sh "touch .env"
            echo "Created empty .env file"
          }
        }
      }
    }

    stage('login to ecr') {
      steps {
        // login must target the registry root (no repository suffix)
        sh """
          aws ecr get-login-password --region ${awsRegion} \
          | docker login --username AWS --password-stdin ${registryId}
        """
      }
    }

    stage('Build Docker Image') {
      steps {
        // tag once with repo+tag (no duplicate repo in the name)
        sh "docker build -t ${ecrUrl}:${imageTag} -f ${dockerfile} ."
      }
    }

    stage('Push Docker Image To ECR') {
      steps {
        sh "docker push ${ecrUrl}:${imageTag}"
      }
    }

    stage('Clean docker images') {
      steps {
        sh "docker rmi -f ${ecrUrl}:${imageTag} || :"
      }
    }

    stage ("Deploy to Environment") {
      steps {
        // update Helm values: repository + tag, commit, and push back
        sh """
          cd ${helmDir}
          git pull
          yq eval -i '.image.repository = "${ecrUrl}"' values.yaml
          yq eval -i '.image.tag = "${imageTag}"' values.yaml
          git add values.yaml
          git commit -m 'update image to ${ecrUrl}:${imageTag}' || true
          git push origin ${branchName}
          cat values.yaml
        """
      }
    }
  }

  post {
    always {
      echo 'Pipeline completed!'
    }
  }
}
