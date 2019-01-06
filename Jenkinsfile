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
      parallel {
        stage('Build dev') {
          // build any non-master branch under the ':develop' tag
          when { not { branch 'master' } }
          steps {
            sh '''
              docker pull raspbian/jessie:latest

              docker build -f "Dockerfile" -t dankempster/jenkins-ansible:develop .
            '''
          }
        }

        stage('Build master') {
          // Only build master under the ':latest' tags
          when { branch 'master' }
          steps {
            sh '''
              docker pull raspbian/jessie:latest

              docker build -f "Dockerfile" -t dankempster/jenkins-ansible:latest .
            '''
          }
        }
      }
    }

    stage('Publish') {
      parallel {
        stage('Publish: Develop branch') {
          // Only push the develop branch to the public as :develop branch
          when { branch 'develop' }
          steps {
            withDockerRegistry([credentialsId: "com.docker.hub.dankempster", url: ""]) {
              sh 'docker push dankempster/jenkins-ansible:develop'
            }
          }
        }

        stage('Publish: Master branch') {
          // Publish master branch to the public
          when { branch 'master' }
          steps {
            withDockerRegistry([credentialsId: "com.docker.hub.dankempster", url: ""]) {
              sh 'docker push dankempster/jenkins-ansible:latest'
            }
          }
        }
      }
    }
  }
}
