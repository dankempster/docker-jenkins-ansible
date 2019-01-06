pipeline {

  agent {
    label 'amd64'
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

    stage('Test') {
      parallel {
        stage('Test dev') {
          // build any non-master branch under the ':develop' tag
          when { not { branch 'master' } }
          steps {
            sh '''
              curl -fsSL https://goss.rocks/install | GOSS_DST=./

              ./dgoss run dankempster/jenkins-ansible:develop
            '''
          }
        }

        stage('Test master') {
          // Only build master under the ':latest' tags
          when { branch 'master' }
          steps {
            sh '''
              curl -fsSL https://goss.rocks/install | GOSS_DST=./

              ./dgoss run dankempster/jenkins-ansible:latest
            '''
          }
        }
      }
    }

    stage('Run') {
      parallel {
        stage('Run dev') {
          // build any non-master branch under the ':develop' tag
          when { not { branch 'master' } }
          steps {
            sh '''
              containerId=$(docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro dankempster/jenkins-ansible:develop)

              docker exec --tty $containerId env TERM=xterm ansible --version

              docker stop $containerId
              docker rm -v $containerId
            '''
          }
        }

        stage('Run master') {
          // Only build master under the ':latest' tags
          when { branch 'master' }
          steps {
            sh '''
              containerId=$(docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro dankempster/jenkins-ansible:latest)

              docker exec --tty $containerId env TERM=xterm ansible --version

              docker stop $containerId
              docker rm -v $containerId
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
