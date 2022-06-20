@Library('slack-notification')
import org.gradiant.jenkins.slack.SlackNotifier

pipeline {
    agent none

    triggers {
        cron('@midnight')
    }

    stages {
        stage('Python Tests') {
            matrix {
                axes {
                    axis {
                        name 'PYTHON_VERSION'
                        values '2.7', '3.3', '3.4', '3.5', '3.6', '3.10'
                    }
                }
                stages {
                    stage('module') {
                        agent {
                            dockerfile { 
                                filename 'techniques/applications/systemUpdateCampaign/1.0/modules/compat.Dockerfile'
                                additionalBuildArgs  "--build-arg USER_ID=${env.JENKINS_UID} --build-arg PYTHON_VERSION=${PYTHON_VERSION}"
                            }
                        }
                        steps {
                            dir ('techniques/applications/systemUpdateCampaign/1.0/modules/') {
                                sh script: 'make test', label: 'system-updates base tests'
                            }
                        }
                        post {
                            always {
                                script {
                                    new SlackNotifier().notifyResult("python-team")
                                }
                            }
                        }
                    }
                }
            }
        }
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
                stage('system-updates') {
                    agent {
                        dockerfile { 
                            filename 'techniques/applications/systemUpdateCampaign/1.0/modules/Dockerfile'
                            additionalBuildArgs  "--build-arg USER_ID=${env.JENKINS_UID}"
                        }
                    }
                    steps {
                        dir ('techniques/applications/systemUpdateCampaign/1.0/modules/') {
                            sh script: 'make check', label: 'system-updates tests'
                        }
                    }
                    post {
                        always {
                            script {
                                new SlackNotifier().notifyResult("python-team")
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
