#!/usr/bin/env groovy

def REPOSITORY_OWNER = "192.168.85.20:5000"
def IMAGE_TAG = "build-${env.BUILD_NUMBER}"

if (env.BRANCH_NAME == 'develop' || env.BRANCH_NAME == 'master') {
  
  REPOSITORY_DEBIAN9 = "jenkins-debian9-ansible"
  REPOSITORY_RASPBIAN = "jenkins-raspbian-stretch"
}
else {
  def SAFE_JOB_NAME = env.JOB_NAME.replace("/", "-").replace("%2F", "-").toLowerCase()
  REPOSITORY_DEBIAN9 = "${SAFE_JOB_NAME}-debian9"
  REPOSITORY_RASPBIAN = "${SAFE_JOB_NAME}-raspbian"
}

IMAGE_NAME_DEBIAN9 = "${REPOSITORY_OWNER}/${REPOSITORY_DEBIAN9}"
IMAGE_NAME_RASPBIAN = "${REPOSITORY_OWNER}/${REPOSITORY_RASPBIAN}"


pipeline {


  agent none


  environment {
    ANT_ARGS = '-logger org.apache.tools.ant.listener.AnsiColorLogger'
  }


  stages {

    stage('Prepare') {
      agent any

      steps {
        script {
          echo "BRANCH_NAME: ${env.BRANCH_NAME}"
          echo "CHANGE_ID: ${env.CHANGE_ID}"
          echo "CHANGE_BRANCH: ${env.CHANGE_BRANCH}"
          echo "CHANGE_TAG: ${env.CHANGE_BRANCH}"

          sh 'printenv'
        }
      }
    }

    stage('Build') {
      parallel {


        stage('Debian 9') {
          agent {
            label 'x86_64'
          }

          steps {            
            ansiColor('xterm') {
              withAnt(installation: 'System') {
                sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_DEBIAN9} -Dimage.tag=${IMAGE_TAG} build"
              }
            }
          }

          post {
            success {
              sh "docker push ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            }
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            }
          }
        }


        stage('Raspbian Stretch') {
          agent {
            label 'raspberrypi_3'
          }

          steps {
            ansiColor('xterm') {
              withAnt(installation: 'System') {
                sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_RASPBIAN} -Dimage.tag=${IMAGE_TAG} build"
              }
            }
          }

          post {
            success {
              sh "docker push ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            }
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            }
          }
        }
      }
    }


    stage('Tests') {
      parallel {


        stage('Goss: Debian') {
          agent {
            label 'x86_64'
          }

          steps {
            ansiColor('xterm') {
              withAnt(installation: 'System') {
                sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_DEBIAN9} -Dimage.tag=${IMAGE_TAG} goss-junit"
              }
            }
          }

          post {
            always {
              junit 'build/reports/**/*.xml'
            }
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            }
          }
        }


        stage('Goss: Raspbian Stretch') {
          agent {
            label 'raspberrypi_3'
          }

          steps {
            ansiColor('xterm') {
              withAnt(installation: 'System') {
                sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_RASPBIAN} -Dimage.tag=${IMAGE_TAG} goss-junit"
              }
            }
          }

          post {
            always {
              junit 'build/reports/**/*.xml'
            }
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            }
          }
        }


      }
    }


    stage('UATs') {
      when {
          anyOf { // Run UATs for

            // master branch
            changeRequest branch: 'master'

            // develop branch
            changeRequest branch: 'develop'

            // merges with 'master' as the target
            changeRequest target: 'master'

            // all release branches, even before they're a PR
            changeRequest id: '', branch: 'release/*', comparator: 'GLOB'

            // all PRs
            expression { env.CHANGE_ID.isNumber() }
          }
      }

      parallel {


        stage('Debian 9') {
          agent {
            label 'x86_64'
          }

          steps {
            echo "Building ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            script {
              try {
                ansiColor('xterm') {
                  withAnt(installation: 'System') {
                    sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_DEBIAN9} -Dimage.tag=${IMAGE_TAG} uat-jenkins-config"
                  }
                  sh "bin/uat-junit.sh build/reports/uat-jenkins-config-debian9.xml jenkins-config -p Jenkins-config successfully built using ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
                }
              }
              catch (Exception e) {
                  sh "bin/uat-junit.sh build/reports/uat-jenkins-config-debian9.xml jenkins-config -f Jenkins-config failed to build using ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
              }
            }
          }

          post {
            failure {
              ansiColor('xterm') {
                withAnt(installation: 'System') {
                  sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_DEBIAN9} -Dimage.tag=${IMAGE_TAG} destroy-uat-jenkins-config"
                }
              }
            }
            always {
              junit 'build/reports/uat-jenkins-config-debian9.xml'
            }
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            }
          }
        }


        stage('Raspbian Stretch') {
          agent {
            label 'raspberrypi_3'
          }

          steps {
            echo "Building ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            script {
              try {
                ansiColor('xterm') {
                  withAnt(installation: 'System') {
                    sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_RASPBIAN} -Dimage.tag=${IMAGE_TAG} uat-jenkins-config"
                  }
                  sh "bin/uat-junit.sh build/reports/uat-jenkins-config-raspbian.xml jenkins-config -p Jenkins-config successfully built using ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
                }
              }
              catch (Exception e) {
                sh "bin/uat-junit.sh build/reports/uat-jenkins-config-raspbian.xml jenkins-config -f Jenkins-config failed to build using ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
              }
            }
          }

          post {
            failure {
              ansiColor('xterm') {
                withAnt(installation: 'System') {
                  sh "ant -Dbuild.number=${env.BUILD_NUMBER} -Dimage.name=${IMAGE_NAME_RASPBIAN} -Dimage.tag=${IMAGE_TAG} destroy-uat-jenkins-config"
                }
              }
            }
            always {
              junit 'build/reports/uat-jenkins-config-raspbian.xml'
            }
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            }
          }
        }


      }
    }


    stage('Publish') {
      when {
        anyOf { // Only publish if...
          
          // 'develop' branch
          branch 'develop'

          // OR
          allOf {
            // Build is 'STABLE'
            expression {
              currentBuild.result != 'UNSTABLE'
            }
            // AND
            anyOf {
              // is 'master' branch
              branch 'master'

              // OR is 'release' branch, authored by a trusted domain and is targeted to 'matser' branch
              changeRequest authorEmail: '*@dankempster.co.uk', branch: 'release/*', comparator: 'GLOB', target: 'master'
            }
          }
        }
      }

      parallel {
        stage('Debian 9') {
          agent {
            label 'x86_64'
          }

          steps {
            script {
              def PUBLISH_TAG = getPublishTag()
              def PUBLISH_NAME = "dankempster/${REPOSITORY_DEBIAN9}:${PUBLISH_TAG}"
            }
            echo "Publishing ${PUBLISH_NAME}"
            sh "docker pull ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            sh "docker tag ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG} ${PUBLISH_NAME}"
            withDockerRegistry([credentialsId: "com.docker.hub.dankempster", url: ""]) {
              sh "docker push ${PUBLISH_NAME}"
            }
          }

          post {
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_DEBIAN9}:${IMAGE_TAG}"
            }
          }
        }


        stage('Raspbian Stretch') {
          agent {
            label 'raspberrypi_3'
          }

          steps {
            script {
              def PUBLISH_TAG = getPublishTag()
              def PUBLISH_NAME = "dankempster/${REPOSITORY_RASPBIAN}:${PUBLISH_TAG}"
            }
            echo "Publishing ${PUBLISH_NAME}"
            sh "docker pull ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            sh "docker tag ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG} ${PUBLISH_NAME}"
            withDockerRegistry([credentialsId: "com.docker.hub.dankempster", url: ""]) {
              sh "docker push ${PUBLISH_NAME}"
            }
          }

          post {
            cleanup {
              sh "docker rmi --force ${IMAGE_NAME_RASPBIAN}:${IMAGE_TAG}"
            }
          }
        }
      }
    }


  }
}


def getPublishTag()
{    
  switch (env.BRANCH_NAME) {
    // case ~/^master$/:
    case "master":
      return 'latest';

    case "develop":
      return 'develop';

    case ~/^PR-[0-9]+$/:
      switch (env.CHANGE_BRANCH) {
        case ~/^release\/v?(.*)$/:
          return "${Matcher.lastMatcher[0][1]}"
      }

    default:
      def message = "Don't know how to create PUBLISH_TAG"
      echo "${message}"
      throw new Exception("${message}")
  }
}

