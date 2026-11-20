# Jenkins Health Check + Flask Pipeline

One Git repo drives two Jenkins jobs:

- **Freestyle job**: checks out the repo and runs a shell health-check script.
- **Pipeline job**: reads the `Jenkinsfile` from this repo and runs **Build → Test → Deploy** on a Flask app.

When you push a commit, the next build of each job runs the new code. The job settings don't change.

```
GitHub repo ──► HealthCheck-Freestyle : checkout → ./health-check.sh
           └──► Flask-Pipeline        : checkout → Build → Test → Deploy
```

## Files

| File | What it does |
|---|---|
| `health-check.sh` | Checks that disk use is below 90% and that a service returns HTTP 200 (Jenkins by default, or a URL passed as the first argument). Exits 1 if either check fails, which fails the build. |
| `app.py` | Flask app: `/` returns a release message, `/health` returns `OK` |
| `requirements.txt` | Flask 2.1.2 and Werkzeug 2.1.2 |
| `test_app.py` | Unit tests for both routes |
| `Jenkinsfile` | Pipeline: **Build** (venv + pip install), **Test** (unittest), **Deploy** (copy to `flask-app-deploy/`) |
| `jenkins/Dockerfile` | Jenkins image with Python and the Git and Pipeline plugins |
| `jenkins/freestyle-config.xml` | `HealthCheck-Freestyle` job: Git checkout, Execute shell `./health-check.sh` |
| `jenkins/pipeline-config.xml` | `Flask-Pipeline` job: Pipeline script from SCM, script path `Jenkinsfile` |

## Run locally

```bash
./health-check.sh
python3 -m venv venv && venv/bin/pip install -r requirements.txt
venv/bin/python -m unittest -v
venv/bin/python app.py        # http://localhost:5000
```

---

## Jenkins setup

**1. Jenkins with Python.** [`jenkins/Dockerfile`](jenkins/Dockerfile) adds Python, venv, and the Git and Pipeline plugins to the official Jenkins image.

```bash
docker build -t jenkins-python jenkins/
docker run -d --name jenkins --restart unless-stopped -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home jenkins-python
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open http://localhost:8080 and log in as `admin` with the password that last command prints.

**2. Freestyle job.** New Item → `HealthCheck-Freestyle` → Freestyle project
- Source Code Management: Git, URL `https://github.com/mauryapg13/jenkins-healthcheck-flask.git`, branch `*/main`
- Build step: Execute shell, `./health-check.sh`

**3. Pipeline job.** New Item → `Flask-Pipeline` → Pipeline
- Definition: *Pipeline script from SCM*, Git, same URL, branch `*/main`
- Script path: `Jenkinsfile`

Or create both jobs from the saved configs (`jcli` is defined under [Demo commands](#demo-commands)):
```bash
jcli create-job HealthCheck-Freestyle < jenkins/freestyle-config.xml
jcli create-job Flask-Pipeline < jenkins/pipeline-config.xml
```

**4. Run them.** Click **Build Now** on each job, then open **Console Output**.

---

## Demo commands

Run this once per terminal tab. It defines `jcli`, a shortcut for the Jenkins CLI:

```bash
docker start jenkins
alias jcli='docker exec -i jenkins sh -c '\''java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/jenkins_home/secrets/initialAdminPassword) "$@"'\'' _'
docker exec jenkins sh -c 'curl -s -o /var/jenkins_home/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar'
cd ~/jenkins-healthcheck-flask
jcli list-jobs
```

### 1. Repo with the script, Flask app, tests and Jenkinsfile
```bash
ls -l
git ls-files -s health-check.sh      # 100755 = executable
git log --oneline
```

### 2. Freestyle job runs the script
```bash
jcli get-job HealthCheck-Freestyle | grep -E '<url>|<name>|<command>'
jcli build HealthCheck-Freestyle -s -v | tail -10
```
**Expect:** `Status: HEALTHY`, then `Finished: SUCCESS`

### 3. Pipeline job from SCM with Build, Test and Deploy stages
```bash
jcli get-job Flask-Pipeline | grep -E 'CpsScmFlowDefinition|<url>|scriptPath'
grep "stage(" Jenkinsfile
```

### 4. Run the pipeline and verify
```bash
jcli build Flask-Pipeline -s -v | grep -E '\((Build|Test|Deploy)\)|Flask |Ran |^OK|Hello from|Finished'
docker exec jenkins ls -l /var/jenkins_home/workspace/Flask-Pipeline/flask-app-deploy
```
**Expect:** `Ran 2 tests` and `OK`, `Finished: SUCCESS`, and `app.py` and `requirements.txt` in the deploy folder.

**Browser:** Flask-Pipeline → latest build → **Pipeline Overview** shows all stages green.

### 5. Push a change and rerun
```bash
sed -i '' 's/Health Check v2/Health Check v3/' health-check.sh
sed -i '' 's/Release v2/Release v3/' app.py test_app.py
git commit -am "Update to v3" && git push
jcli build HealthCheck-Freestyle -s -v | grep -E 'Commit message|Health Check|Finished'
jcli build Flask-Pipeline -s -v | grep -E 'Commit message|Ran |Hello from|Finished'
```
**Expect:** both jobs check out the new commit and print `Health Check v3` and `Release v3`.

To reset to v2 for another demo, run:
```bash
sed -i '' 's/v3/v2/' health-check.sh app.py test_app.py && git commit -am "Back to v2" && git push
```

## Notes

- The deploy folder and venv are build outputs. They live in the Jenkins workspace inside the container (`/var/jenkins_home/workspace/Flask-Pipeline/`), not in this repo.
- Werkzeug is pinned because Flask 2.1 can't import Werkzeug 3.x.
