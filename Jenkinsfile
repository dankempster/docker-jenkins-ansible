#!/usr/bin/env groovy

def IMAGE_NAME = "dankempster/jenkins-ansible"
def IMAGE_TAG = "build"

pipeline {

  agent {
    label 'amd64'
  }

  stages {

    stage('Prepare') {
      steps {
        sh '''
          docker pull $(head -n 1 Dockerfile | cut -d " " -f 2)

          [ -d bin ] || mkdir bin

          curl -fsSL https://goss.rocks/install | GOSS_DST=./bin sh
        '''
      }
    }

    stage('Build') {
      steps {
        script { 
          if (env.BRANCH_NAME == 'develop') {
            IMAGE_TAG = 'develop'
          }
          else if (env.BRANCH_NAME == 'master') {
            IMAGE_TAG = 'latest'
          }
        }
        
        sh "docker build -f Dockerfile -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }

    stage('Tests') {
      steps {
        sh 'rm -fr build/*'
        sh '[ -d build/reports ] || mkdir -p build/reports'
        sh '[ -d build/raw-reports ] || mkdir -p build/raw-reports'

        sh """
          export GOSS_PATH=\$(pwd)/bin/goss
          export GOSS_OPTS="--retry-timeout 30s --sleep 1s --format junit"

          # ./bin/dgoss run --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro ${IMAGE_NAME}:${IMAGE_TAG}

          ./bin/dgoss run --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro ${IMAGE_NAME}:${IMAGE_TAG} | \\grep '<' > build/raw-reports/goss-output.txt
        """
      }
      post {
        always {
          sh """
            cd build/raw-reports

            awk '
            FNR==1 {
               path = namex = FILENAME;
               sub(/^.*\\//,   "", namex);
               sub(namex "\$", "", path );
               name = ext  = namex;
               sub(/\\.[^.]*\$/, "", name);
               sub("^" name,   "", ext );
            }
            /<\\?xml / {
               if (out) close(out);
               out = path name (++file) ext ;
               print "Spliting to " out " ...";
            }
            /<\\?xml /,/<\\/testsuite>/ {
               print \$0 > out
            }
            ' goss-output.txt

            mv goss-output\$(ls -l | grep -P goss-output[0-9]+\\.txt | wc -l).txt ../reports/goss-junit.xml
          """

          junit 'build/reports/**/*.xml'
        }
      }
    }

    stage('Ansible Test') {
      steps {
        script {
          CONTAINER_ID = sh(
            script: "docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro ${IMAGE_NAME}:${IMAGE_TAG}",
            returnStdout: true
          ).trim()
        }
        
        sh "docker exec --tty ${CONTAINER_ID} env TERM=xterm ansible --version"

        sh """
          docker stop ${CONTAINER_ID}
          docker rm ${CONTAINER_ID}
        """
      }
    }

    stage('Publish') {
      when {
        anyOf {
          branch 'develop'
          anyOf {
            branch 'master'
          }
        }
      }
      steps {
        withDockerRegistry([credentialsId: "com.docker.hub.dankempster", url: ""]) {
          sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
        }
      }
    }
  }
}
