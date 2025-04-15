@Library('slack-notification')
import org.gradiant.jenkins.slack.SlackNotifier

pipeline {
    agent none

    triggers {
        cron('@midnight')
    }

    stages {
        stage('Tests') {
            parallel {
                stage('shell') {
                    agent {
                        dockerfile {
                            label 'generic-docker'
                            filename 'ci/common.Dockerfile'
                            args '-u 0:0'
                        }
                    }
                    steps {
                        sh script: './qa-test --shell', label: 'shell scripts lint'
                        sh script: './qa-test --license', label: 'license header check'
                    }
                    post {
                        always {
                            // linters results
                            recordIssues enabledForFailure: true, failOnError: true, sourceCodeEncoding: 'UTF-8',
                                         tool: checkStyle(pattern: '.shellcheck/*.log', reportEncoding: 'UTF-8', name: 'Shell scripts')

                            script {
                                new SlackNotifier().notifyResult("shell-team")
                            }
                        }
                    }
                }
                stage('powershell lint') {
                    agent {
                        dockerfile {
                            label "generic-docker"
                            filename 'ci/linter.Dockerfile'
                            additionalBuildArgs "--build-arg VERSION=1.20.0 --build-arg USER_ID=${env.JENKINS_UID}"
                            args "--read-only --mount type=tmpfs,destination=/tmp"
                        }
                    }
                    steps {
                        sh script: './qa-test --dsc', label: 'powershell techniques lint'
                    }
                }

                stage('typos') {
                    agent {
                        dockerfile {
                            label 'generic-docker'
                            filename 'ci/common.Dockerfile'
                            args '-u 0:0'
                        }
                    }
                    steps {
                        sh script: 'typos', label: 'check typos'
                    }
                    post {
                        always {
                            script {
                                new SlackNotifier().notifyResult("shell-team")
                            }
                        }
                    }
                }
                stage('test') {
                    agent {
                        dockerfile {
                            label 'generic-docker'
                            filename 'ci/cf-promises.Dockerfile'
                            args '-u 0:0'
                        }
                    }
                    steps {
                        sh script: 'make all', label: 'build techniques'
                        sh script: 'PATH="/opt/rudder/bin:$PATH" make', label: 'check techniques'
                        sh script: 'make clean', label: 'cleanup'
                        sh script: 'git clean -fdx', label: 'cleanup'
                    }
                    post {
                        always {
                            script {
                                new SlackNotifier().notifyResult("shell-team")
                            }
                        }
                    }
                }
            }
        }
    }
}
