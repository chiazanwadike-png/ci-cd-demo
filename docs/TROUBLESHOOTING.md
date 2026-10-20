\# CI/CD Pipeline — Troubleshooting, Incident Resolution, and Lessons Learned



\*\*Project:\*\* Automated CI/CD Pipeline Using Docker, GitHub Actions, PowerShell, and Kubernetes  

\*\*Repository:\*\* https://github.com/chiazanwadike-png/ci-cd-demo  

\*\*Environment:\*\* Windows 10/11, PowerShell, Docker Desktop, Kubernetes kind cluster  

\*\*Primary project date:\*\* October 2026  

\*\*Application:\*\* NGINX web server hosting a custom HTML website



\---



\## 1. Purpose of This Document



This document records the technical challenges, configuration errors, troubleshooting procedures, and solutions encountered while building an automated Continuous Integration and Continuous Deployment (CI/CD) pipeline.



The project integrates:



\- Git and GitHub for source control.

\- Docker for application containerization.

\- GitHub Actions for automated builds and testing.

\- GitHub Container Registry (GHCR) for image storage.

\- Kubernetes for orchestration and application deployment.

\- PowerShell for source synchronization, image monitoring, and deployment automation.

\- Windows Task Scheduler for automatically launching monitoring scripts.

\- Persistent logging and rollback functionality for deployment recovery.



The goal is to demonstrate practical troubleshooting, problem-solving, infrastructure automation, and operational understanding.



\---



\## Incident 1 — Docker Image Not Found Locally



\### Problem



When attempting to run my custom Docker application, Docker returned an image retrieval error.



\*\*Command executed:\*\*



`docker run -d --name ci-cd-demo -p 8083:80 ci-cd-demo:v1`



\*\*Error message:\*\*



`Unable to find image 'ci-cd-demo:v1' locally`



`pull access denied for ci-cd-demo, repository does not exist or may require 'docker login'`



\### Root Cause



The custom Docker image had not yet been successfully built.



Further investigation showed that the Dockerfile had been saved with an incorrect filename:



`dockerfile.txt`



Docker expected a file named `Dockerfile` without a `.txt` extension.



\### Troubleshooting Procedure



I inspected the project directory using:



`Get-ChildItem`



This revealed that the folder contained `dockerfile.txt` and `index.html`.



\### Resolution



Renamed the file:



`Rename-Item -Path "dockerfile.txt" -NewName "Dockerfile"`



Built the Docker image:



`docker build -t ci-cd-demo:v1 .`



Verified the image:



`docker images ci-cd-demo`



Started the container:



`docker run -d --name ci-cd-demo -p 8083:80 ci-cd-demo:v1`



Verified the container using `docker ps`.



\### Result



The application successfully ran on `http://localhost:8083`.



\### Lesson Learned



Docker containers depend on images being available locally or in an accessible registry.



Correct file naming, image building, and execution order are fundamental Docker troubleshooting concepts.



\---



\## Incident 2 — Kubernetes Cluster Initialization Problems



\### Problem



During earlier Kubernetes training, newer local kind cluster configurations sometimes failed to initialize correctly.



Observed symptoms included:



`failed to init node with kubeadm`



`connect: connection refused`



Communication attempts to the Kubernetes API server occasionally failed.



\### Investigation



I examined Docker Desktop, Kubernetes contexts, cluster configuration, and resource constraints.



The environment used Windows, WSL2, Docker Desktop, and a local Kubernetes cluster.



\### Resolution



I continued working with the Kubernetes v1.35.8 kind-based cluster that had demonstrated stable operation.



The cluster consisted of:



\- One control-plane node.

\- Three worker nodes.



All four nodes were subsequently used for Kubernetes training and the CI/CD project.



\### Important Finding



The precise root cause of the intermittent newer-cluster initialization failures was not conclusively established.



\### Lesson Learned



A working container engine does not automatically guarantee a healthy Kubernetes control plane.



Cluster troubleshooting requires checking node health, API server connectivity, container runtime status, Kubernetes contexts, and available system resources.



\---



\## Incident 3 — Kubernetes YAML Indentation Errors



\### Problem



While learning Kubernetes manifests, configuration files sometimes failed validation because of incorrect indentation.



One error occurred while adding a Secret environment variable:



`error converting YAML to JSON: yaml: line 32: did not find expected key`



\### Root Cause



The `DEMO\_API\_KEY` environment variable entry was not aligned correctly with the other entries under the container's `env` configuration.



\### Troubleshooting



Reviewed the relevant YAML section and compared indentation levels.



Validated the configuration using:



`kubectl apply --dry-run=client -f nginx-demo.yaml`



\### Resolution



Corrected the indentation and reapplied the manifest.



The Secret was successfully read by the running container.



\*\*Verification command:\*\*



`kubectl exec deployment/nginx-yaml-demo -- printenv DEMO\_API\_KEY`



The command returned the expected practice value.



\### Lesson Learned



YAML uses indentation to define configuration structure.



A single misaligned entry can prevent Kubernetes from accepting an otherwise correct configuration.



Client-side validation should be performed before applying configuration changes.



Real credential values should never be printed into public troubleshooting evidence.



\---



\## Incident 4 — Git Repository Initially Had No Commits



\### Problem



After initializing Git and staging project files, the repository displayed:



`No commits yet`



The repository contained staged files but had no saved commit history.



\### Root Cause



Files had been added to Git's staging area, but the first commit had not yet been created.



\### Resolution



Created the initial commit:



`git commit -m "Initial Docker NGINX application"`



Renamed the primary branch:



`git branch -M main`



Verified the repository:



`git status`



\### Result



Git reported:



`On branch main`



`nothing to commit, working tree clean`



The repository was successfully pushed to GitHub.



\### Lesson Learned



Staging and committing are separate Git operations.



Staging selects changes, while committing creates a versioned record in repository history.



\---



\## Incident 5 — GitHub Actions Workflow Failed Due to YAML Formatting



\### Problem



The GitHub Actions workflow returned:



`Invalid workflow file`



`You have an error in your yaml syntax on line 14`



\### Root Cause



The container registry login step was not aligned with the other GitHub Actions steps.



Two website verification commands were also placed underneath the image publishing step instead of the application testing step.



The error-handling step was incomplete.



\### Troubleshooting Procedure



Reviewed `.github/workflows/docker-build.yml`.



Checked the indentation beneath:



\- `jobs`

\- `build-and-test`

\- `steps`

\- `run`

\- `with`



Verified that each workflow step was correctly aligned.



\### Resolution



Replaced the incorrectly formatted sections with a corrected workflow configuration.



Committed and pushed the changes to GitHub.



\### Result



GitHub Actions successfully parsed and executed the workflow.



\### Lesson Learned



GitHub Actions workflows depend on valid YAML structure.



A workflow can fail before running any application code if its configuration is incorrectly formatted.



\---



\## Incident 6 — GitHub Actions HTTP Test Failed



\### Problem



The Docker build succeeded, and the NGINX container started, but the workflow initially failed during application testing.



An observed error was:



`Process completed with exit code 56`



\### Investigation



Examined the GitHub Actions execution logs.



Verified that the Docker image was built and the container launched.



Reviewed the HTTP test performed using `curl`.



\### Finding



Exit code 56 indicates a failure while receiving network data.



The precise cause of the original failure was not conclusively established. Application startup timing was one possible explanation, but it was not proven.



\### Resolution



Improved the test to:



\- Wait for NGINX to respond.

\- Retry unsuccessful HTTP requests.

\- Save the returned HTML.

\- Verify that the expected website heading appears.

\- Print Docker container logs when troubleshooting failures.



\### Result



The updated GitHub Actions workflow successfully built the image, ran the container, and verified the webpage.



\### Lesson Learned



A successful container build does not guarantee that the application is ready to serve requests.



CI pipelines should distinguish image-building success from application-health verification and provide meaningful failure diagnostics.



\---



\## Incident 7 — GitHub Actions Node.js Deprecation Warning



\### Problem



GitHub Actions reported a Node.js runtime deprecation warning involving Docker login authentication.



The warning identified:



`docker/login-action@v3

