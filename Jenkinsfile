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

    stage('Static Code Analysis') {
      steps {
        sh '[ -d build/reports ] || mkdir -p build/reports'
        
        sh 'ansible-lint -p tasks/ > build/reports/ansiblelint.txt'
        
        sh 'yamllint -c yaml-lint.yml -f parsable . > build/reports/yamllint.txt'

        step([
          $class: 'ViolationsToGitHubRecorder',
          config: [
            gitHubUrl: 'https://api.github.com/',
            repositoryOwner: 'dankempster',
            repositoryName: 'docker-jenkins-ansible',
            pullRequestId: '2',

            // Only specify one of these!
            credentialsId: 'com.github.dankempster.token',

            createCommentWithAllSingleFileComments: true,
            createSingleFileComments: true,
            commentOnlyChangedContent: true,
            minSeverity: 'INFO',
            keepOldComments: false,

            commentTemplate: """
            **Reporter**: {{violation.reporter}}{{#violation.rule}}

            **Rule**: {{violation.rule}}{{/violation.rule}}
            **Severity**: {{violation.severity}}
            **File**: {{violation.file}} L{{violation.startLine}}{{#violation.source}}

            **Source**: {{violation.source}}{{/violation.source}}

            {{violation.message}}
            """,

            violationConfigs: [
              [ pattern: 'build/reports/ansiblelint\\.txt$', parser: 'FLAKE8', reporter: 'AnsibleLint' ],
              [ pattern: 'build/reports/yamllint\\.txt$', parser: 'YAMLLINT', reporter: 'YAMLLint' ],
            ]
          ]
        ])
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
          export GOSS_OPTS="--retry-timeout 60s --sleep 5s --format junit"

          # ./bin/dgoss run --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro ${IMAGE_NAME}:${IMAGE_TAG}

          ./bin/dgoss run --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro -p 8080 ${IMAGE_NAME}:${IMAGE_TAG} | \\grep '<' > build/raw-reports/goss-output.txt
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
