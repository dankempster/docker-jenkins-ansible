pipeline {

  agent {
    label 'raspberrypi'
  }

  stages {
    stage('Update') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh '''
          docker pull raspbian/stretch:latest

          docker build -f "Dockerfile" -t dankempster/raspbian-stretch-ansible:latest .
        '''
      }
    }
    
    stage('Publish') {
      when {
        branch 'master'
      }
    
      steps {
        withDockerRegistry([credentialsId: "com.docker.hub.dankempster", url: ""]) {
          sh 'docker push dankempster/raspbian-stretch-ansible:latest'
        }
      }
    }
  }
}
