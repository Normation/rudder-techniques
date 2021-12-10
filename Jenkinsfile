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
                            filename 'ci/shellcheck.Dockerfile'
                        }
                    }
                    steps {
                        sh script: './qa-test --shell', label: 'shell scripts lint'
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
                stage('typos') {
                    agent { 
                        dockerfile { 
                            filename 'ci/typos.Dockerfile'
                            additionalBuildArgs  '--build-arg VERSION=1.0'
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
                            filename 'ci/cf-promises.Dockerfile'
                            args  "--user 0"
                        }
                    }
                    steps {
                        sh script: 'make all', label: 'build techniques'
                        sh script: 'PATH="/opt/rudder/bin:$PATH" make', label: 'check techniques'
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
