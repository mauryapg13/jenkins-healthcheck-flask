pipeline {
    agent any

    environment {
        VENV = "${WORKSPACE}/venv"
    }

    stages {
        stage('Build') {
            steps {
                echo 'Installing dependencies...'
                sh '''
                python3 -m venv ${VENV}
                ${VENV}/bin/pip install --quiet -r requirements.txt
                ${VENV}/bin/pip list | grep -iE '^(flask|werkzeug) '
                '''
            }
        }
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                sh '${VENV}/bin/python -m unittest discover -s . -v'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                sh '''
                mkdir -p ${WORKSPACE}/flask-app-deploy
                cp app.py requirements.txt ${WORKSPACE}/flask-app-deploy/
                ls -l ${WORKSPACE}/flask-app-deploy
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the logs for more details.'
        }
    }
}
