#!groovy
pipeline {
    agent none
    stages {
        stage('s2i') {
            agent {
                node {
                    label "scrm-lxc-dev"
                }
            }
            steps {
                checkout(scm)
                sh "s2i . docker"
            }
        }
    }
}
