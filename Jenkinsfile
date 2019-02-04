#!/usr/bin/env groovy

def IMAGE_NAME = "dankempster/jenkins-ansible"
def IMAGE_TAG = "build"

pipeline {

  agent {
    label 'amd64'
  }

  stages {

    stage('Build') {
      steps {

        // Ensure we have the latest base docker image
        sh "docker pull \$(head -n 1 Dockerfile | cut -d \" \" -f 2)"

        script { 
          if (env.BRANCH_NAME == 'develop') {
            IMAGE_TAG = 'develop'
          }
          else if (env.BRANCH_NAME == 'master') {
            IMAGE_TAG = 'latest'
          }
          else {
            IMAGE_TAG = 'build'
          }
        }
        
        sh "docker build -f Dockerfile -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }

    stage('Tests') {
      parallel {
        stage('Goss') {
          steps {

            // Prepare build directory
            sh 'rm -fr build/{reports,raw-reports}'
            sh '[ -d build/reports ] || mkdir -p build/reports'
            sh '[ -d build/raw-reports ] || mkdir -p build/raw-reports'

            // Install Goss & dgoss
            sh '[ -d bin ] || mkdir bin'
            sh 'curl -fsSL https://goss.rocks/install | GOSS_DST=./bin sh'
            sh "chmod +rx ./bin/{goss,dgoss}"

            // Run the tests
            sh """
              export GOSS_PATH=\$(pwd)/bin/goss
              export GOSS_OPTS="--retry-timeout 60s --sleep 5s --format junit"

              ./bin/dgoss run --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro -p 8080 ${IMAGE_NAME}:${IMAGE_TAG} | \\grep '<' > build/raw-reports/goss-output.txt
            """
          }
          post {
            always {
              // The following is required to extract the last junit report
              // from Goss output.
              // This is required because
              //  - goss outputs the junit format to STDOUT, with other output.
              //  - goss prints out junit for each "retry", so the final output
              //      is multiple junit reports. One for each "try" during the
              //      tests.
              //  - I have to use the goss' retry feature so it "waits" for
              //      Jenkins to load.
              //
              sh """
                cd build/raw-reports

                # split Goss output into multiple files numbered sequentially.
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

                # use the highest numbered file as Goss' final junit report
                mv goss-output\$(ls -l | grep -P goss-output[0-9]+\\.txt | wc -l).txt ../reports/goss-junit.xml
              """

              junit 'build/reports/**/*.xml'
            }
          }
        }

        stage('Ansible\'s Version') {
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
      }
    }

    stage('Publish') {
      when {
        anyOf {
          branch 'develop'
          allOf {
            expression {
              currentBuild.result != 'UNSTABLE'
            }
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
