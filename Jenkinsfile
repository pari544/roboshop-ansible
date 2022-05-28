pipeline {
    agent any

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
            sh 'bash create-ec2-with-env.sh ${COMPONENT} ${ENV}'
            sh 'ls -ltr'
         }
       }

       stage('Run Ansible Playbook') {

        steps {
           sh 'ls -ltr'
           sh 'ansible-playbook roboshop.yml -e ENV=${ENV} -e ansible_user=${SSH_USR} -e ansible_password=${SSH_PSW} -e HOST=${COMPONENT} -e ROLE_NAME=${COMPONENT}'

        }
       }
    }

}