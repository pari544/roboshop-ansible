@Library('roboshop-library') _

pipeline {
    agent any

    options {
       ansiColor('xterm')
    }
    parameters {
            string(name: 'ENV', defaultValue: '', description: 'Which Environment')
            string(name: 'COMPONENT', defaultValue: '', description: 'Which Component')

        }

     environment {
       SSH = credentials('SSH')
     }
    stages {

       stage('Create Instance') {
         steps {
            script {
                ec2InstanceCreate.create("${COMPONENT}", "${ENV}")
            }
         }
       }

       stage('Run Ansible Playbook') {

        steps {
           sh 'ansible-playbook -i inv roboshop.yml -e ENV=${ENV} -e ansible_user=${SSH_USR} -e ansible_password=${SSH_PSW} -e HOST=${COMPONENT} -e ROLE_NAME=${COMPONENT}'

        }
       }
    }

}