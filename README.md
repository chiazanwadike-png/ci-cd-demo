## Complete Project Documentation

[Download the Complete CI/CD Project Guidebook](docs/CI_CD_DevOps_Project_Guidebook.docx)

\# Automated CI/CD Pipeline with Docker, GitHub Actions, PowerShell \& Kubernetes



\## Project Overview



This project demonstrates the development of an automated Continuous Integration and Continuous Delivery/Deployment (CI/CD) pipeline using Docker, GitHub Actions, GitHub Container Registry (GHCR), Windows PowerShell, and Kubernetes.



The objective was to build a system that automatically detects local application changes, synchronizes them to GitHub, builds and tests a Docker image, publishes the image to a container registry, and deploys the updated application into a local Kubernetes cluster.



\*\*Repository:\*\* https://github.com/chiazanwadike-png/ci-cd-demo



\*\*Environment:\*\* Windows, Docker Desktop, Kubernetes kind cluster



\*\*Application:\*\* Custom HTML website hosted through NGINX



\*\*Status:\*\* Automated application updates demonstrated successfully; logging and isolated rollback recovery verified.



\---



\## Architecture



```mermaid

flowchart TD

&#x20;   A\["Developer saves index.html"] --> B\["PowerShell Git Auto-Sync"]

&#x20;   B --> C\["GitHub Repository"]

&#x20;   C --> D\["GitHub Actions"]

&#x20;   D --> E\["Build and Test Docker Image"]

&#x20;   E --> F\["GitHub Container Registry"]

&#x20;   F --> G\["PowerShell Deployment Watcher"]

&#x20;   G --> H\["Kubernetes Deployment"]

&#x20;   H --> I\["Kubernetes ClusterIP Service"]

&#x20;   I --> J\["Localhost Website"]



&#x20;   G --> K\["Deployment and Error Logs"]

&#x20;   G --> L\["Rollback Logic"]



&#x20;   M\["Windows Task Scheduler"] --> B

&#x20;   M --> G

```



\*\*Deployment process:\*\* Save code → Git auto-sync → GitHub Actions → Docker image → GHCR → PowerShell watcher → Kubernetes → Website.



The Kubernetes environment runs locally through Docker Desktop. GitHub-hosted runners do not connect directly to the private local cluster; the Windows deployment watcher checks GHCR for new images and initiates deployments locally.



\---



\## Technologies Used



| Technology | Purpose |

|---|---|

| Git and GitHub | Version control and source-code management |

| Docker | Containerize the HTML/NGINX application |

| Docker Desktop | Run containers and the local Kubernetes environment |

| Kubernetes (kind) | Container orchestration and rolling deployments |

| GitHub Actions | Automated image building and application testing |

| GitHub Container Registry | Store published Docker images |

| PowerShell | Git synchronization, deployment monitoring, logging, and recovery automation |

| Windows Task Scheduler | Launch automation scripts when signing in |

| YAML | Configure GitHub Actions and Kubernetes |

| HTML | Sample application used to demonstrate automatic deployments |



\---



\## Key Features



\### 1. Automatic Git Synchronization



The `git-autosync.ps1` script monitors changes to `index.html`.



When a saved change is detected, the script automatically stages, commits, and pushes the HTML file to the GitHub repository.



This eliminates the need to manually execute Git commands for routine website updates.



\### 2. Automated Continuous Integration



GitHub Actions automatically performs the following operations when changes reach the `main` branch:



\- Checks out the repository.

\- Builds the Docker image.

\- Starts the NGINX container.

\- Tests the application using HTTP requests.

\- Verifies the expected website content.

\- Publishes the successful image to GHCR.



GitHub Actions generates a build number that is inserted into the website during image creation.



\### 3. Container Registry Integration



Successful Docker images are published to:



`ghcr.io/chiazanwadike-png/ci-cd-demo:latest`



The deployment watcher resolves the registry image to its SHA-256 digest.



Using image digests provides an exact reference to the image deployed by Kubernetes.



\### 4. Kubernetes Deployment Automation



The `deploy-watch.ps1` script compares the published registry image digest with the image configured in the Kubernetes Deployment.



When a new image is available, the script updates the Deployment and monitors the rolling update.



The application runs in the `development` namespace and is exposed through a ClusterIP Service.



\### 5. Automated Deployment Logging



The deployment watcher writes timestamped events to:



`%LOCALAPPDATA%\\ci-cd-demo\\deploy-watch.log`



Recorded events include image checks, new-image detection, deployment attempts, rollout results, and errors.



\### 6. Rollback Protection



The deployment watcher includes logic designed to restore a previous image when deployment or application-content verification fails.



A separate, controlled rollback test was successfully completed using `ci-cd-rollback-lab`.



The test deployed a nonexistent image, detected the rollout timeout, and automatically restored the previous healthy image.



This isolated test demonstrates recovery logic; comprehensive failure testing of the main scheduled watcher remains future work.



\---



\## Kubernetes Configuration



The Kubernetes application uses:



\- A Deployment named `ci-cd-demo`.

\- The `development` namespace.

\- A ClusterIP Service named `ci-cd-demo-service`.

\- HTTP readiness checks on port 80.

\- Rolling updates with `maxUnavailable: 0` and `maxSurge: 1`.

\- CPU and memory requests and limits.

\- Image digests to reference deployed images precisely.



The local lab uses a four-node kind cluster, including one control-plane node and three worker nodes.



\---



\## Running the Application Locally



\### Prerequisites



Install Git, Docker Desktop, and kubectl. A functioning local Kubernetes cluster is required for the Kubernetes deployment exercises.



\### Clone the repository



```powershell

git clone https://github.com/chiazanwadike-png/ci-cd-demo.git

cd ci-cd-demo

```



\### Build the Docker image



```powershell

docker build -t ci-cd-demo:local .

```



\### Run the Docker container



```powershell

docker run -d --name ci-cd-demo-local -p 8083:80 ci-cd-demo:local

```



Open `http://localhost:8083`.



\### Deploy to Kubernetes



First, ensure the local cluster is running and the `development` namespace exists.



```powershell

kubectl get nodes

kubectl create namespace development

kubectl apply -f kubernetes.yaml

```



If the namespace already exists, skip its creation.



The published GHCR image must be accessible to the cluster. Private packages require image-pull authentication.



\### Verify the Deployment



```powershell

kubectl get deployments -n development

kubectl get pods -n development

kubectl get services -n development

kubectl rollout status deployment/ci-cd-demo -n development

```



\### Access the Kubernetes Website



```powershell

kubectl port-forward -n development service/ci-cd-demo-service 8087:80

```



Open `http://127.0.0.1:8087`.



Port forwarding is intended for local development and testing, not public application hosting.



\---



\## Automatic Deployment Monitoring



The project uses two PowerShell scripts:



\*\*`git-autosync.ps1`\*\* monitors local website changes and automatically pushes them to GitHub.



\*\*`deploy-watch.ps1`\*\* monitors GHCR for image changes and updates Kubernetes when a new image becomes available.



Windows Task Scheduler is configured to launch both watchers.



The local deployment system operates only when the computer is awake, the cluster is accessible, the scripts are running, and the required authentication and networking are available.



\---



\## Deployment and Rollback Test Results



\### Successful Continuous Delivery



An application change was saved locally and automatically synchronized to GitHub.



GitHub Actions created a new Docker image and published it to GHCR.



The deployment watcher detected the updated digest, and the changed website content appeared in the Kubernetes-hosted application.



The application also demonstrated automatically generated build numbers.



\### Controlled Rollback Test — October 20, 2026



| Time | Event |

|---|---|

| 14:40:58 | Rollback test started |

| 14:40:58 | Invalid image deployment initiated |

| 14:41:59 | Kubernetes rollout timeout detected |

| 14:41:59 | Automatic restoration initiated |

| 14:42:02 | Previous healthy image restored |



\*\*Result:\*\* Passed.



The isolated rollback test restored `nginx:stable-alpine`, and Kubernetes reported `1/1` available.



The recovery completed approximately three seconds after failure detection, following the intentional 60-second rollout timeout.



\---



\## Troubleshooting and Lessons Learned



| Issue | Cause or Finding | Resolution |

|---|---|---|

| Docker image not found | Custom image had not been built, and Dockerfile used `.txt` extension | Renamed Dockerfile and built the image |

| GitHub Actions YAML error | Incorrect indentation and misplaced workflow commands | Corrected YAML structure |

| HTTP testing failure | `curl` reported exit code 56; exact original cause not conclusively established | Added retries, response inspection, and diagnostic logs |

| GitHub Actions runtime warning | Node.js runtime deprecation | Updated action versions |

| PowerShell script blocked | Execution policy restricted scripts | Used process-scoped `RemoteSigned` |

| Outdated website appeared | Old browser response or port-forward session was suspected | Verified Pod content and used a fresh port-forward |

| Duplicate deployment watchers | Manually launched and scheduled processes overlapped | Consolidated monitoring under Task Scheduler |

| No deployment history file | Initial watcher only printed output | Added persistent timestamped logs |

| Failed Kubernetes image update | Nonexistent image could not start | Automatic restoration tested successfully |



\### Major Lessons



This project reinforced the importance of:



\- Understanding the difference between Docker images and running containers.

\- Verifying application health instead of assuming a deployment succeeded.

\- Using image digests for deterministic Kubernetes deployments.

\- Troubleshooting workflow errors from logs and exit codes.

\- Separating CI testing from deployment automation.

\- Keeping deployment history and rollback evidence.

\- Understanding the limitations of local Kubernetes environments.



\---



\## Current Limitations and Future Improvements



This project is a local learning lab rather than a production deployment platform.



Future improvements include:



\- Testing more failure scenarios in the main deployment watcher.

\- Adding application-level health monitoring and notifications.

\- Implementing log rotation and retention policies.

\- Replacing automatic direct pushes to `main` with a review and approval workflow.

\- Improving credential management and supply-chain security.

\- Adding automated integration tests.

\- Deploying a similar architecture to a cloud-hosted Kubernetes environment such as Amazon EKS.



\---



\## Project Demonstration



A recorded walkthrough will cover the architecture, Docker image build, GitHub Actions workflow, GHCR publishing, PowerShell watchers, Kubernetes deployment, error logs, and rollback test.



Screenshots and demonstration materials will be added as the project documentation is completed.



\---



\## Conclusion



This project demonstrates practical experience integrating source control, containers, CI/CD workflows, registry publishing, Kubernetes orchestration, PowerShell automation, deployment monitoring, and recovery testing.



The primary achievement is a working local development-to-deployment pipeline in which saving website changes can trigger automatic Git synchronization, image building, publishing, and Kubernetes deployment.

