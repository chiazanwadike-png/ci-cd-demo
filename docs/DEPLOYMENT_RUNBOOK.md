\# Complete CI/CD Pipeline Recreation Runbook



\*\*Project:\*\* Automated CI/CD Pipeline Using Docker, GitHub Actions, PowerShell, and Kubernetes  

\*\*Repository:\*\* https://github.com/chiazanwadike-png/ci-cd-demo  

\*\*Operating system:\*\* Windows with PowerShell and Docker Desktop  

\*\*Kubernetes:\*\* Local kind-based cluster, Kubernetes v1.35.8  

\*\*Application:\*\* Custom HTML website hosted by NGINX  

\*\*Primary namespace:\*\* `development`



\---



\# Chapter 1 — Project Objective



\## 1.1 What am I building?



An automated Continuous Integration and Continuous Deployment pipeline that connects local website development with Kubernetes.



The process is:



1\. A developer saves changes to `index.html`.

2\. A PowerShell watcher detects the saved changes.

3\. Git automatically commits and pushes the HTML file to GitHub.

4\. GitHub Actions builds and tests a new Docker image.

5\. GitHub Actions publishes the image to GitHub Container Registry (GHCR).

6\. A second PowerShell watcher checks GHCR for new image digests.

7\. Kubernetes deploys the updated image.

8\. The application becomes available through a Kubernetes Service.

9\. Deployment events and errors are written to persistent logs.



Windows Task Scheduler launches the two PowerShell watchers automatically when the user signs in.



\## 1.2 Learning objectives



By completing this project, I demonstrate knowledge of:



\- Dockerfiles, container images, containers, and registries.

\- Git repositories, commits, branches, and remote synchronization.

\- GitHub Actions workflow creation and troubleshooting.

\- Kubernetes Pods, Deployments, Services, namespaces, and rolling updates.

\- PowerShell scripting and background automation.

\- Windows Task Scheduler.

\- Image digests and release identification.

\- Deployment logging, incident diagnosis, and rollback procedures.



\## 1.3 Important architecture distinction



The application runs in a Kubernetes cluster on my Windows laptop.



GitHub-hosted Actions runners build, test, and publish Docker images, but they do not directly access my local Kubernetes API.



Instead, my local PowerShell watcher retrieves published image information from GHCR and updates Kubernetes from inside my Windows environment.



This is a local DevOps training and portfolio environment, not an always-online production hosting system.



\---



\# Chapter 2 — Prerequisites and Environment Verification



\## 2.1 Required software



The following tools are required:



| Software | Purpose |

|---|---|

| Windows PowerShell | Execute scripts and infrastructure commands |

| Docker Desktop | Run Docker containers and support the local Kubernetes cluster |

| Docker CLI | Build, inspect, and run images |

| Git | Manage local source control |

| GitHub account | Host source code and CI workflows |

| kubectl | Manage Kubernetes resources |

| Kubernetes cluster | Run the containerized application |

| Windows Task Scheduler | Launch automatic background watchers |



The original project used:



\- Git 2.56.0.windows.1

\- Docker 29.8.2

\- Kubernetes 1.35.8



Other supported versions may work, but their behavior should be verified rather than assumed identical.



\## 2.2 Open Docker Desktop



1\. Launch Docker Desktop.

2\. Wait for the Docker Engine to become ready.

3\. Ensure Docker is using Linux containers.

4\. Check that the local Kubernetes cluster is available.



Docker Desktop should be configured to start automatically when signing in to Windows if unattended deployment after login is required.



\## 2.3 Verify Docker



In PowerShell:



```powershell

docker --version

docker info

docker ps

```



\*\*Expected result:\*\* Docker responds without a daemon connection error.



`docker --version` alone confirms the CLI installation, not Docker Engine availability. The additional commands verify engine connectivity.



\## 2.4 Verify Git



```powershell

git --version

```



\## 2.5 Verify Kubernetes



```powershell

kubectl version --client

kubectl config current-context

kubectl get nodes

kubectl get namespaces

```



The original lab used a four-node kind-based cluster:



\- `desktop-control-plane`

\- `desktop-worker`

\- `desktop-worker2`

\- `desktop-worker3`



All nodes should report `Ready`.



\*\*Important:\*\* Do not apply or delete resources until confirming that `kubectl` points to the intended local cluster.



If recreating the cluster on another computer, install and configure kind or use a supported Docker Desktop Kubernetes provisioner. The original cluster setup used Docker Desktop's local Kubernetes integration; the cluster-creation method and names may differ between installations.



\---



\# Chapter 3 — Prepare the Kubernetes Development Environment



\## 3.1 Create the development namespace



```powershell

kubectl create namespace development

```



Verify:



```powershell

kubectl get namespaces

```



If `development` already exists, do not attempt to recreate it.



\## 3.2 Understand the namespace



The `development` namespace organizes the project's Kubernetes resources.



Namespaces provide logical separation and help with administration and access control. They do not automatically provide complete network isolation.



\## 3.3 Review existing Deployments



```powershell

kubectl get deployments -A

```



This command displays Deployments across all namespaces.



During the original training, I created the `my-app` and `nginx-yaml-demo` Deployments before building the CI/CD application.



Those earlier exercises introduced scaling, self-healing, YAML, ConfigMaps, Secrets, resource limits, health probes, Services, and namespaces.



They are useful prerequisites but are not required to run the final CI/CD application.



\---



\# Chapter 4 — Create the Website



\## 4.1 Create the project directory



```powershell

cd "$HOME"

New-Item -ItemType Directory -Force "kubernetes-labs\\ci-cd-demo"

cd "$HOME\\kubernetes-labs\\ci-cd-demo"

```



\## 4.2 Create index.html



```powershell

notepad index.html

```



Insert:



```html

<!DOCTYPE html>

<html>

<head>

&#x20;   <title>My First CI/CD Project</title>

</head>

<body>

&#x20;   <h1>My First CI/CD Deployment!</h1>

&#x20;   <h2>Docker + Kubernetes + GitHub Actions</h2>

&#x20;   <h2>Build \_\_BUILD\_NUMBER\_\_</h2>

&#x20;   <p>My application has been updated!</p>

&#x20;   <p>Built and tested with GitHub Actions.</p>

&#x20;   <p>Deployed to Kubernetes.</p>

</body>

</html>

```



Save the file.



The `\_\_BUILD\_NUMBER\_\_` placeholder will be replaced automatically when Docker builds the application.



This eliminates the need to manually edit the version number for every new release.



\---



\# Chapter 5 — Build a Docker Image



\## 5.1 Create the Dockerfile



```powershell

notepad Dockerfile

```



Insert:



```dockerfile

FROM nginx:stable-alpine



ARG BUILD\_NUMBER=local



COPY index.html /usr/share/nginx/html/index.html



RUN sed -i "s/\_\_BUILD\_NUMBER\_\_/${BUILD\_NUMBER}/g" /usr/share/nginx/html/index.html



EXPOSE 80

```



Save the file as `Dockerfile`, without a `.txt` extension.



\## 5.2 Explain the Dockerfile



| Instruction | Meaning |

|---|---|

| `FROM` | Selects the NGINX base image |

| `ARG` | Accepts a build-time variable |

| `COPY` | Places the HTML file inside the image |

| `RUN` | Replaces the build-number placeholder |

| `EXPOSE` | Documents port 80 used by NGINX |



\## 5.3 Build the image locally



```powershell

docker build -t ci-cd-demo:local .

```



The trailing period means Docker uses the current directory as the build context.



\## 5.4 Verify the image



```powershell

docker images ci-cd-demo

```



\## 5.5 Run the application



```powershell

docker run -d --name ci-cd-demo-local -p 8083:80 ci-cd-demo:local

```



Verify:



```powershell

docker ps

```



Open:



`http://localhost:8083`



The webpage should display:



\*\*My First CI/CD Deployment!\*\*



and a local build identifier.



\## 5.6 Stop the container when finished



```powershell

docker stop ci-cd-demo-local

docker rm ci-cd-demo-local

```



Do this only when the local test container is no longer needed.



\---



\# Chapter 6 — Configure Git and GitHub



\## 6.1 Initialize the repository



From the project directory:



```powershell

git init

git branch -M main

```



\## 6.2 Stage the application files



```powershell

git add Dockerfile index.html

```



\## 6.3 Create the first commit



```powershell

git commit -m "Initial Docker NGINX application"

```



If Git has not been configured with an author name and email, configure them using your actual intended Git identity.



\## 6.4 Create a GitHub repository



On GitHub, create an initially empty repository named:



`ci-cd-demo`



Do not initialize it with a separate README or other conflicting initial commit when following these commands.



\## 6.5 Connect the remote repository



```powershell

git remote add origin https://github.com/chiazanwadike-png/ci-cd-demo.git

```



\## 6.6 Push source code



```powershell

git push -u origin main

```



Authenticate through the normal GitHub sign-in process when prompted.



\## 6.7 Verify



```powershell

git status

git remote -v

git log --oneline -5

```



GitHub should display the Dockerfile and HTML source code.



\---



\# Chapter 7 — Create the GitHub Actions CI Pipeline



\## 7.1 Create the workflow directory



```powershell

New-Item -ItemType Directory -Force ".github\\workflows"

notepad .github\\workflows\\docker-build.yml

```



\## 7.2 Add the workflow



```yaml

name: Docker Build and Test



on:

&#x20; push:

&#x20;   branches: \[main]

&#x20; pull\_request:

&#x20;   branches: \[main]



permissions:

&#x20; contents: read

&#x20; packages: write



jobs:

&#x20; build-and-test:

&#x20;   runs-on: ubuntu-24.04



&#x20;   steps:

&#x20;     - name: Checkout repository

&#x20;       uses: actions/checkout@v6



&#x20;     - name: Build Docker image

&#x20;       run: docker build --build-arg BUILD\_NUMBER=${{ github.run\_number }} -t ci-cd-demo:test .



&#x20;     - name: Run Docker container

&#x20;       run: docker run -d --name ci-cd-test -p 8083:80 ci-cd-demo:test



&#x20;     - name: Show running containers

&#x20;       run: docker ps -a



&#x20;     - name: Test application

&#x20;       run: |

&#x20;         echo "Waiting for NGINX to start..."



&#x20;         ready=false



&#x20;         for attempt in {1..20}; do

&#x20;           if curl --fail --silent --show-error \\

&#x20;             --max-time 5 \\

&#x20;             --output response.html \\

&#x20;             http://127.0.0.1:8083/; then

&#x20;             ready=true

&#x20;             break

&#x20;           fi



&#x20;           echo "Attempt $attempt failed. Retrying..."

&#x20;           sleep 2

&#x20;         done



&#x20;         if \[ "$ready" != true ]; then

&#x20;           docker ps -a

&#x20;           docker logs ci-cd-test

&#x20;           exit 1

&#x20;         fi



&#x20;         grep -Fq "My First CI/CD Deployment!" response.html

&#x20;         grep -Eq "Build \[0-9]+" response.html



&#x20;         echo "Application tests passed."



&#x20;     - name: Log in to GitHub Container Registry

&#x20;       if: github.event\_name == 'push' \&\& github.ref == 'refs/heads/main'

&#x20;       uses: docker/login-action@v4

&#x20;       with:

&#x20;         registry: ghcr.io

&#x20;         username: ${{ github.actor }}

&#x20;         password: ${{ secrets.GITHUB\_TOKEN }}



&#x20;     - name: Publish Docker image

&#x20;       if: github.event\_name == 'push' \&\& github.ref == 'refs/heads/main'

&#x20;       run: |

&#x20;         docker tag ci-cd-demo:test ghcr.io/${{ github.repository }}:latest

&#x20;         docker push ghcr.io/${{ github.repository }}:latest



&#x20;     - name: Show logs if something fails

&#x20;       if: failure()

&#x20;       run: docker logs ci-cd-test

```



This is a reference workflow reflecting the established design. Action versions and hosted-runner availability should be checked when reproducing the project in the future.



\## 7.3 Understand the CI workflow



The workflow performs these operations:



1\. Downloads repository source code.

2\. Builds the Docker image.

3\. Starts a test container.

4\. Tests the website using HTTP requests.

5\. Confirms the expected page content and build number.

6\. Authenticates with GHCR on a push to `main`.

7\. Publishes the Docker image.



The build number comes from GitHub Actions' `github.run\_number` variable.



\## 7.4 Commit the workflow



```powershell

git add .github/workflows/docker-build.yml

git commit -m "Add automated Docker CI pipeline"

git push origin main

```



\## 7.5 Verify GitHub Actions



Open:



https://github.com/chiazanwadike-png/ci-cd-demo/actions



Select the newest \*\*Docker Build and Test\*\* workflow.



Verify that the image build, HTTP test, registry login, and image publishing steps complete successfully.



\---



\# Chapter 8 — Publish to GitHub Container Registry



\## 8.1 Published image



The project's GHCR address is:



```text

ghcr.io/chiazanwadike-png/ci-cd-demo:latest

```



The published image can be viewed through the GitHub account's Packages section.



\## 8.2 Verify the image digest



```powershell

docker buildx imagetools inspect ghcr.io/chiazanwadike-png/ci-cd-demo:latest --format '{{json .Manifest.Digest}}'

```



A digest identifies the exact published image contents.



Unlike the mutable `latest` tag, a digest provides a stable reference to a specific image.



\## 8.3 Registry visibility



A public GHCR image can generally be pulled without authentication.



Private GHCR images require suitable image-pull credentials when deploying to Kubernetes.



For this public portfolio lab, the package was configured to be accessible by the local cluster.



Do not publish private access tokens or credentials inside the GitHub repository.



\---



\# Chapter 9 — Deploy the Application to Kubernetes



\## 9.1 Create kubernetes.yaml



```powershell

notepad kubernetes.yaml

```



Insert:



```yaml

apiVersion: apps/v1

kind: Deployment

metadata:

&#x20; name: ci-cd-demo

&#x20; namespace: development

spec:

&#x20; replicas: 1

&#x20; minReadySeconds: 5

&#x20; strategy:

&#x20;   type: RollingUpdate

&#x20;   rollingUpdate:

&#x20;     maxSurge: 1

&#x20;     maxUnavailable: 0

&#x20; selector:

&#x20;   matchLabels:

&#x20;     app: ci-cd-demo

&#x20; template:

&#x20;   metadata:

&#x20;     labels:

&#x20;       app: ci-cd-demo

&#x20;   spec:

&#x20;     containers:

&#x20;       - name: ci-cd-demo

&#x20;         image: ghcr.io/chiazanwadike-png/ci-cd-demo:latest

&#x20;         imagePullPolicy: Always

&#x20;         ports:

&#x20;           - containerPort: 80

&#x20;         readinessProbe:

&#x20;           httpGet:

&#x20;             path: /

&#x20;             port: 80

&#x20;           initialDelaySeconds: 2

&#x20;           periodSeconds: 5

&#x20;           timeoutSeconds: 2

&#x20;           failureThreshold: 3

&#x20;         resources:

&#x20;           requests:

&#x20;             cpu: "50m"

&#x20;             memory: "64Mi"

&#x20;           limits:

&#x20;             cpu: "250m"

&#x20;             memory: "128Mi"

\---

apiVersion: v1

kind: Service

metadata:

&#x20; name: ci-cd-demo-service

&#x20; namespace: development

spec:

&#x20; type: ClusterIP

&#x20; selector:

&#x20;   app: ci-cd-demo

&#x20; ports:

&#x20;   - port: 80

&#x20;     targetPort: 80

```



This incorporates the readiness settings that were added during the original project.



\## 9.2 Validate the YAML



```powershell

kubectl apply --dry-run=client -f kubernetes.yaml

```



\## 9.3 Deploy



```powershell

kubectl apply -f kubernetes.yaml

```



\## 9.4 Verify the rollout



```powershell

kubectl rollout status deployment/ci-cd-demo -n development --timeout=300s

kubectl get deployments -n development

kubectl get pods -n development

kubectl get services -n development

```



The application Deployment should eventually report `1/1` available.



\## 9.5 Explain the Kubernetes architecture



\*\*Deployment:\*\* Maintains the desired application state and manages rolling updates.



\*\*Pod:\*\* Runs the NGINX application container.



\*\*ReplicaSet:\*\* Maintains the Deployment's requested Pod replicas.



\*\*ClusterIP Service:\*\* Gives the application a stable internal service endpoint.



\*\*Readiness probe:\*\* Checks whether NGINX can respond to HTTP requests.



\*\*RollingUpdate strategy:\*\* Allows a replacement Pod to start while the existing healthy Pod remains available.



\## 9.6 Open the Kubernetes application



```powershell

kubectl port-forward -n development service/ci-cd-demo-service 8087:80

```



Open:



`http://127.0.0.1:8087`



Port forwarding is intended for local testing.



\---



\# Chapter 10 — Configure the GHCR Deployment Watcher



\## 10.1 Purpose



The deployment watcher bridges the cloud-hosted image registry and the locally running Kubernetes cluster.



It periodically checks GHCR, resolves the `latest` tag to an exact image digest, compares that digest with the configured Kubernetes image, and initiates a rollout if the image has changed.



\## 10.2 File



`deploy-watch.ps1`



\## 10.3 Configuration



The watcher uses:



```powershell

$image = "ghcr.io/chiazanwadike-png/ci-cd-demo"

$tag = "${image}:latest"

$namespace = "development"

$deploymentName = "ci-cd-demo"

$containerName = "ci-cd-demo"

```



The full rollback-enabled `deploy-watch.ps1` should be kept in the repository alongside this runbook. Use that version rather than combining fragments from older watcher revisions.



\## 10.4 Digest inspection



The central registry command is:



```powershell

docker buildx imagetools inspect $tag --format '{{json .Manifest.Digest}}'

```



\## 10.5 Read the Kubernetes image



```powershell

kubectl get deployment ci-cd-demo -n development -o json

```



The watcher extracts the image configured for the application container.



\## 10.6 Update Kubernetes



When the published digest differs from the configured digest, the watcher executes an image update equivalent to:



```powershell

kubectl set image deployment/ci-cd-demo "ci-cd-demo=IMAGE\_REFERENCE" -n development

```



`IMAGE\_REFERENCE` represents the resolved image address with its digest.



It then checks rollout completion:



```powershell

kubectl rollout status deployment/ci-cd-demo -n development --timeout=300s

```



In routine operation, the watcher runs these commands automatically rather than requiring manual intervention.



\## 10.7 Start a watcher manually for testing



```powershell

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

.\\deploy-watch.ps1

```



Stop the manual watcher with `Ctrl+C` before enabling the Task Scheduler-managed instance.



Do not run multiple deployment watchers against the same Deployment.



\---



\# Chapter 11 — Add Persistent Deployment Logging



\## 11.1 Log location



```text

%LOCALAPPDATA%\\ci-cd-demo\\deploy-watch.log

```



\## 11.2 Purpose



The log records:



\- Watcher startup.

\- Registry checks.

\- Whether a new image was found.

\- Previous and new image references.

\- Kubernetes command output.

\- Successful rollouts.

\- Errors and rollback attempts.



\## 11.3 View recent events



```powershell

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\deploy-watch.log" -Tail 20

```



\## 11.4 Filter errors



```powershell

Select-String -Path "$env:LOCALAPPDATA\\ci-cd-demo\\deploy-watch.log" -Pattern '\\\[ERROR\\]'

```



\## 11.5 Filter successful events



```powershell

Select-String -Path "$env:LOCALAPPDATA\\ci-cd-demo\\deploy-watch.log" -Pattern '\\\[SUCCESS\\]'

```



\## 11.6 Example event



```text

\[INFO] Checking GHCR for image changes.

\[INFO] New image detected.

\[INFO] Previous image: ghcr.io/example/app@sha256:...

\[INFO] New image: ghcr.io/example/app@sha256:...

\[SUCCESS] Deployment successful: sha256:...

```



The example uses illustrative image identifiers.



Persistent logs make it possible to investigate deployment behavior after the original PowerShell window has closed.



Log rotation and retention are future improvements.



\---



\# Chapter 12 — Configure Automatic Git Synchronization



\## 12.1 Purpose



The `git-autosync.ps1` script monitors the local `index.html` file.



When it detects a saved change, it creates a Git commit and pushes that commit to GitHub.



This eliminates routine manual Git commands when updating the training website.



\## 12.2 Important behavior



The script checks for file changes, waits for the file to settle, and automatically performs operations equivalent to:



```powershell

git add -- index.html

git commit --only -m "Auto-sync website update" -- index.html

git push origin main

```



The complete working `git-autosync.ps1` should be included in the repository.



The script only automatically commits the designated HTML file. Changes to infrastructure files, workflows, and documentation are managed separately.



\## 12.3 Start it for testing



```powershell

Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

.\\git-autosync.ps1

```



\## 12.4 Verification



Edit an ordinary paragraph in `index.html` and save it.



The watcher should generate messages similar to:



```text

Website changes detected.

Changes committed successfully.

Pushing changes to GitHub...

GitHub sync successful.

```



No manual Git staging, committing, or pushing should be necessary for the HTML update.



\## 12.5 Git synchronization log



```text

%LOCALAPPDATA%\\ci-cd-demo\\git-autosync.log

```



Read it using:



```powershell

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\git-autosync.log" -Tail 20

```



\## 12.6 Security consideration



Automatically committing every saved website change to `main` is appropriate for this controlled learning lab.



Production environments generally require pull requests, code review, protected branches, testing, and deployment approvals.



\---



\# Chapter 13 — Configure Windows Task Scheduler



Two scheduled tasks are used.



\## 13.1 Deployment watcher task



Task name:



`Kubernetes CI-CD Deployment Watcher`



Program:



```text

powershell.exe

```



Arguments:



```text

\-NoProfile -ExecutionPolicy RemoteSigned -File "C:\\Users\\chiaz\\kubernetes-labs\\ci-cd-demo\\deploy-watch.ps1"

```



Start-in directory:



```text

C:\\Users\\chiaz\\kubernetes-labs\\ci-cd-demo

```



\## 13.2 Git synchronization task



Task name:



`GitHub Auto Sync`



Program:



```text

powershell.exe

```



Arguments:



```text

\-NoProfile -ExecutionPolicy RemoteSigned -File "C:\\Users\\chiaz\\kubernetes-labs\\ci-cd-demo\\git-autosync.ps1"

```



Start-in directory:



```text

C:\\Users\\chiaz\\kubernetes-labs\\ci-cd-demo

```



\## 13.3 Recommended task settings



\- Trigger: At user logon.

\- Optional startup delay: Two minutes.

\- Run only when the user is logged on.

\- Do not start a second instance when one is already running.

\- Disable the default time limit that stops long-running tasks after three days.



For portable recreation, replace the Windows user directory with the actual project location.



\## 13.4 Verify scheduled tasks



```powershell

Get-ScheduledTask |

Where-Object {

&#x20;   $\_.TaskName -in @(

&#x20;       "GitHub Auto Sync",

&#x20;       "Kubernetes CI-CD Deployment Watcher"

&#x20;   )

} |

Select-Object TaskName, State

```



Both should show `Running` while active.



\## 13.5 Verify the processes



```powershell

Get-CimInstance Win32\_Process |

Where-Object {

&#x20;   $\_.Name -in @("powershell.exe", "pwsh.exe") -and

&#x20;   (

&#x20;       $\_.CommandLine -like "\*git-autosync.ps1\*" -or

&#x20;       $\_.CommandLine -like "\*deploy-watch.ps1\*"

&#x20;   )

} |

Select-Object ProcessId, ParentProcessId, CommandLine

```



There should normally be one instance of each watcher.



Task Scheduler reporting `Running` is not sufficient by itself to prove that the watcher can connect to Docker, GitHub, or Kubernetes. The log files and deployment results provide additional verification.



\---



\# Chapter 14 — Automatic Rollback Protection



\## 14.1 Purpose



Rollback protection attempts to restore a previously working image when a newly deployed image fails its rollout or the configured content checks.



\## 14.2 Main watcher design



The deployment watcher:



1\. Records the previous image.

2\. Detects a new image digest.

3\. Initiates the deployment.

4\. Waits for rollout completion.

5\. Checks required application content.

6\. Logs success or failure.

7\. Attempts to restore the previous image if the new deployment fails.

8\. Records failed digests to prevent continuous retries of known-bad images.



The failed-digest file is stored under:



```text

%LOCALAPPDATA%\\ci-cd-demo\\failed-digests.txt

```



A failed digest should only be cleared after investigating and intentionally authorizing another deployment attempt.



\## 14.3 Controlled rollback test



A separate Deployment named:



`ci-cd-rollback-lab`



was created to avoid disrupting the working website.



The test used:



\*\*Known-good image:\*\* `nginx:stable-alpine`



\*\*Intentionally invalid image:\*\* `nginx:rollback-test-nonexistent-20261020`



\## 14.4 Observed results



| Time | Event |

|---|---|

| 14:40:58 | Failed-image test started |

| 14:41:59 | Rollout timeout detected |

| 14:41:59 | Restoration initiated |

| 14:42:02 | Previous image restored |



The Kubernetes Deployment returned to `1/1` available.



\## 14.5 Review test logs



```powershell

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\rollback-lab.log" -Tail 20

```



\## 14.6 Recovery commands



If manual investigation becomes necessary:



```powershell

kubectl rollout history deployment/ci-cd-demo -n development

kubectl describe deployment ci-cd-demo -n development

kubectl get pods -n development

```



A deliberate manual rollback can be initiated with:



```powershell

kubectl rollout undo deployment/ci-cd-demo -n development

```



Manual rollback should be coordinated with the watcher, because an active watcher may otherwise redeploy the published `latest` image.



\## 14.7 Verification limits



The isolated rollback test passed successfully.



However, not every failure path of the main scheduled deployment watcher has been independently tested.



The test therefore demonstrates foundational automated recovery rather than production-grade fault tolerance.



\---



\# Chapter 15 — Demonstrate End-to-End Automation



\## 15.1 Preparation



Verify:



\- Docker Desktop is running.

\- Kubernetes nodes are Ready.

\- The two scheduled tasks are Running.

\- GitHub Actions is available.

\- GHCR is accessible.

\- The current application is healthy.



\## 15.2 Open the website



```powershell

kubectl port-forward -n development service/ci-cd-demo-service 8087:80

```



Open:



`http://127.0.0.1:8087`



Record the currently displayed build number.



\## 15.3 Make one HTML change



Open:



```powershell

notepad index.html

```



Add a harmless line of text, save, and close Notepad.



Do not manually run Git or Kubernetes deployment commands during the demonstration.



\## 15.4 Observe Git synchronization



Review:



```powershell

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\git-autosync.log" -Tail 20

```



Confirm a successful automatic commit and push.



\## 15.5 Observe GitHub Actions



Open the Actions page and confirm the new build and publish steps succeed.



Record the generated GitHub Actions run number.



\## 15.6 Observe Kubernetes deployment logging



```powershell

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\deploy-watch.log" -Tail 30

```



Confirm that a new image was detected and successfully deployed.



\## 15.7 Verify the running application



```powershell

kubectl exec -n development deployment/ci-cd-demo -- grep "Build" /usr/share/nginx/html/index.html

```



Verify that the build number corresponds to the published workflow run.



Refresh the browser using a new query parameter if necessary.



The changed text should appear on the Kubernetes website without manually invoking a deployment.



\---



\# Chapter 16 — Operational Runbook



\## 16.1 Start-of-day verification



Open Docker Desktop and confirm the engine and Kubernetes cluster are available.



Run:



```powershell

docker ps

kubectl config current-context

kubectl get nodes

kubectl get deployments -n development

```



\## 16.2 Check automation status



```powershell

Get-ScheduledTask |

Where-Object {

&#x20;   $\_.TaskName -in @(

&#x20;       "GitHub Auto Sync",

&#x20;       "Kubernetes CI-CD Deployment Watcher"

&#x20;   )

} |

Select-Object TaskName, State

```



\## 16.3 Review logs



```powershell

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\git-autosync.log" -Tail 10

Get-Content "$env:LOCALAPPDATA\\ci-cd-demo\\deploy-watch.log" -Tail 20

```



\## 16.4 Verify running application



```powershell

kubectl get pods -n development

kubectl rollout status deployment/ci-cd-demo -n development

kubectl exec -n development deployment/ci-cd-demo -- grep "Build" /usr/share/nginx/html/index.html

```



\## 16.5 Investigate problems



If Git synchronization fails, inspect its log, Git status, and authentication.



If GitHub Actions fails, inspect the exact workflow step and its logs.



If GHCR publishing fails, inspect registry login, permissions, and publishing output.



If Kubernetes deployment fails, inspect Pods, events, image references, rollout status, and the watcher error log.



Do not immediately restart or delete Pods without first checking which delivery stage failed.



\## 16.6 Shut down the lab



Stop the scheduled watchers when shutting down or intentionally pausing local automation.



Do not delete Kubernetes resources unless a cleanup operation is specifically intended.



Stop temporary port-forward processes using `Ctrl+C`.



Docker Desktop can then be closed if no other workloads need it.



\---



\# Chapter 17 — Troubleshooting and Lessons Learned



The detailed historical troubleshooting journal is maintained in:



`docs/TROUBLESHOOTING.md`



Major issues encountered during the original project included:



1\. Dockerfile incorrectly saved with a `.txt` extension.

2\. Missing locally built Docker image.

3\. Kubernetes cluster initialization and API connectivity issues.

4\. YAML indentation errors.

5\. Git repository without an initial commit.

6\. Invalid GitHub Actions YAML.

7\. HTTP test failure involving curl exit code 56.

8\. Node.js action runtime deprecation warnings.

9\. PowerShell script execution restrictions.

10\. Console output accidentally pasted as commands.

11\. Duplicate deployment watchers.

12\. Outdated localhost content.

13\. Missing Git commits and unpublished application changes.

14\. Manual version-number updates.

15\. Missing persistent deployment logs.

16\. Controlled failed-image deployment and rollback recovery.



Each incident should be explained using its observed symptoms, confirmed or suspected cause, troubleshooting commands, resolution, and learning outcome.



\---



\# Chapter 18 — Portfolio Evidence Checklist



Before recording the final demonstration, capture evidence of:



\- Docker Desktop and running containers.

\- Kubernetes nodes.

\- Development namespace.

\- Healthy application Deployment.

\- Kubernetes Service.

\- Dockerfile and website source.

\- GitHub repository and commit history.

\- Successful GitHub Actions run.

\- Published GHCR image.

\- Running PowerShell watcher processes.

\- Windows Task Scheduler tasks.

\- Git auto-sync log.

\- Deployment event log.

\- Automatic build number on the website.

\- Isolated rollback failure and recovery log.

\- Mermaid architecture diagram.



Do not expose passwords, personal access tokens, private keys, or sensitive configuration data in screenshots or recordings.



\---



\# Chapter 19 — Project Limitations and Future Enhancements



This project demonstrates working automation in a local learning environment.



It has several important limitations:



\- The computer must remain awake and connected.

\- Docker Desktop and Kubernetes must be available.

\- Scheduled tasks need access to the correct Docker, Git, and Kubernetes environments.

\- Direct automatic commits to `main` are not appropriate for every team.

\- Current readiness checks are basic HTTP checks.

\- The main watcher's recovery logic requires more failure-path testing.

\- Logging does not yet include full rotation and retention controls.

\- Local port forwarding is not public production hosting.

\- GHCR image publishing does not provide a full deployment-approval process.



Possible next improvements include GitOps, deployment approvals, security scanning, signed images, additional integration tests, metrics and alerts, and a cloud-hosted Kubernetes environment such as Amazon EKS.



\---



\# Chapter 20 — Final Project Summary



This project demonstrates an end-to-end automated delivery workflow for a containerized web application.



A local website change is synchronized to GitHub, automatically built and tested, published as a Docker image, and deployed to Kubernetes through a local PowerShell watcher.



Additional components provide persistent deployment logging and foundational automated rollback capability.



The primary technical achievement is understanding not only how the individual technologies work, but how source control, CI/CD, registries, operating-system automation, and Kubernetes interact as one delivery system.



\*\*Final demonstrated skills:\*\* Docker, Git, GitHub, GitHub Actions, GHCR, PowerShell, Windows Task Scheduler, Kubernetes, YAML, deployment diagnostics, logging, and controlled failure recovery.



