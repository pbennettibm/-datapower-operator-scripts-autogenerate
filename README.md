# datapower-operator-scripts

Home of utility scripts for automating datapower-operator tasks.

## Instuctions

**Pre-Reqs**

1. Config the git pre-commit hook to run scripts.
  - Inside the root of this repo run
    ```
    git config core.hooksPath .githooks
    ```
  - Then depending on your OS:
    - Mac
      ```
      chmod ug+x .githooks/pre-commit migrate-backup-dps.sh migrate-backup-route.sh migrate-backup-service.sh
      ```
    - Windows
      ```
      icacls .githooks/pre-commit migrate-backup-dps.sh migrate-backup-route.sh migrate-backup-service.sh /grant *S-1-1-0:F
      ```
      _Note: You may have to use the full path on Windows to correctly authorize the hook to run. We haven't had the ability to test this yet._

2. If planning on deploying with GitOps at any stage, clone the [multi-tenancy-gitops-apps](https://github.com/DataPower-on-Azure/multi-tenancy-gitops-apps) repo into the parent directory of where this repo is currently located on your local machine.

**Checking in/out DataPower backup zip files**
1. Write git commits after adding or removing DataPower backup zip files into the root of this repo.

**Please do not rename any zip files to ensure the git hook works correctly.**
Instead:
1. Move the zip file out of this repo's directory
2. Add & commit the changes
3. Rename the moved zip file
4. Move the renamed zip file back to this repo's directory
5. Add & commit the changes.

### Instructions for deploying DataPower manually on OCS

**Pre-reqs**

1. Login to the OpenShift Web Console.
  - Use the provided url, username and password from either the OpenShift installer, or an admin who holds the credentials.

2. Once logged in the the OpenShift Web Console, log in to the OpenShift CLI.
  - In the upper right corner of the OpenShift Web Console select the IAM user and click "Copy login command" in the drop down menu.
  - In the window that opens, copy the first CLI input and paste it into your CLI of choice.

**Instructions**

1. Install the IBM catalog source to expose IBM operators using the CLI.
  - Inside the root of this repo run
    ```
    oc apply -f ibm-catalog-source.yaml
    ```

2. Install the DataPower operator on all namespaces using the Web Console.
  - Under the "Administrator" tab select "Operators" and then "OperatorHub".
  - In the search bar provided search for `datapower`.
  - Select "IBM DataPower GateWay".
  - Select "Install" and keep all defaults
    - Make sure you are installing on all namespaces 

3. Create a new project namespace to deploy your instance to using the CLI.
  ```
  oc new-project <zip-file-name>-migration
  ```
  
4. (Optional) Check in a DataPower backup zip file if you wish to use your own configuration instead of the sample provided.
  - Remove validation-flow.zip as well to avoid confusion.

5. Gather the keys and certificates you wish to use and create a secret from them.
  - These will be located in the mounted volume from the previous step in the [DataPower-install](https://github.com/DataPower-on-Azure/DataPower-install) repo.
  - If your keys are formatted as .cert/.key then run this command.
    ```
    oc create secret tls <domain>-cert --key=/path/to/my.crt --cert=/path/to/my.key
    ```
  - If they are not then run this command instead.
    ```
    oc create secret generic <domain>-cert --from-file=/path/to/cert --from-file=/path/to/key
    ```

6. Create an admin user credential secret.
  ```
  oc create secret generic datapower-user --from-literal=password=admin
  ```

7. Create a secret to pull the DataPower image from the IBM registry.
  - If attempting to run in any enivornment besides "nonproduction" refer to [Pulling images from the IBM Entitled Registry](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=features-entitled-registry) for instructions.
  - If using an [IBM Entitlement Key](https://myibm.ibm.com/products-services/containerlibrary)
    ```
    oc create secret docker-registry \
      ibm-entitlement-key \
      --docker-username=cp \
      --docker-password=<entitlement-key> \
      --docker-server=cp.icr.io
    ```
  _Note: This is the most common usage._
  - If you want to use a custom Service Account, read the official documentation and edit the appropriate fields in the generated <zipfile>/<zipfile>-dps.yaml file according to the links below.
    - [Pulling images from the IBM Entitled Registry](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=features-entitled-registry) - scroll to "Using a custom Service Account"
    - [serviceAccountName](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=s-serviceaccountname-1)
    - [imagePullSecrets](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=s-imagepullsecrets-1)

8. Add a zip file and commit in git to run scripts and generate files if you haven't done so already.

9. Go into the "backup-output" folder and apply the domain configmaps.
  ```
  cd <zip-file-name>
  cd <zip-file-name>/<zip-file-name>-output
  oc apply -f default-cfg.yaml
  oc apply -f default-local.yaml
  ```
  _Note: If your zip file contains multiple domains, apply the other domains as well.

10. Once the YAML is applied, check the cluster to ensure that everything looks correct.
  ```
  oc get configmap
  ```

11. If you do not have a key/cert secret for each domain, make sure to remove the entire "certs" definition from the affected domain(s) in `<zip-file-name>-dps.yaml`. (Optional)

12. Create the DataPowerService resource in the cluster.
  ```
  oc apply -f <zip-file-name>-dps.yaml
  ```

13. Create a service for the DataPowerService in the cluster.
  ```
  oc apply -f <zip-file-name>-service.yaml
  ```

14. Create a route for the service you just created in the cluster.
  ```
  oc apply -f <zip-file-name>-route.yaml
  ```

15. Either use the OpenShift web console or the command line to get the route's address.
  - If using the web console, under the "Administrator" tab go to "Networking" and then select "Routes".
  - If using the command line.
    ```
    oc get route
    ```

16. Navigate to the route's address to ensure that your DataPower instance is working.

### Instructions for deploying DataPower on OCS with GitOps

**Pre-reqs**

1. Clone the [multi-tenancy-gitops-apps](https://github.com/DataPower-on-Azure/multi-tenancy-gitops-apps) repo into the parent directory of where this repo is currently located on your local machine.
  - If you have already commited a zip file that you wish to use before cloning the above repo for the first time, please:
    - Move the zip file out of this repo's directory
    - Add & commit the changes
    - Rename the moved zip file
    - Move the renamed zip file back to this repo's directory
    - Add & commit the changes.

2. Login to the OpenShift Web Console.
  - Use the provided url, username and password from either the OpenShift installer, or an admin who holds the credentials.

3. Once logged in the the OpenShift Web Console, log in to the OpenShift CLI.
  - In the upper right corner of the OpenShift Web Console select the IAM user and click "Copy login command" in the drop down menu.
  - In the window that opens, copy the first CLI input and paste it into your CLI of choice.

4. Configuration for ODF on OCP 4.10+
  - Delete the `multi-tenancy-gitops` repo from your `GIT_ORG` if it exists.
  - Fork the [Cloud Native Toolkit](https://github.com/cloud-native-toolkit/multi-tenancy-gitops/generate) to your existing `GIT_ORG`.
  - Clone the `multi-tenancy-gitops` repo to your local machine.
  - Navigate to the `/scripts` folder to run the `set-git-source.sh` script.
  - Commit and push.
  - Run the `infra-mod.sh` script to deploy ODF Storage.
  - Commit and push.
  - Navigate to Argo in the OpenShift web console
  - Refresh Argo to see the changes.

**Instructions**

1. Add and commit a DataPower backup zip to this repository.
  - If you already have the zip file commited:
    1. Move the zip file out of this repo's directory
    2. Add & commit the changes
    3. Move the zip file back to this repo's directory
    4. Add & commit the changes.

2. (Optional) Refer to the instructions in [multi-tenancy-gitops-apps](https://github.com/DataPower-on-Azure/multi-tenancy-gitops-apps) if attempting the GitOps deployment on your own.

11. If you do not have a key/cert secret for each domain, make sure to remove the entire "certs" definition from the affected domain(s) in `multi-tenancy-gitops-apps/dp/environments/dev/datapower/<zip-file-name>-dps.yaml`. (Optional)

3. Change directories to the `multi-tenancy-gitops-apps` repo in the terminal and commit the new files and changes that have been automatically made.
  - If your configuration is complex and changes need to be made please examine the files located in the `/dp/environments/dev/datapower` folders.

## Debugging

### `must-gather.sh`

Use this script to gather all DataPower Operator related resources from your Kubernetes/OpenShift cluster.

For usage:

```
./must-gather.sh -h
```


Reference:

- [Guide: Domain configuration](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=guides-domain-configuration)
- [DataPowerService API docs](https://www.ibm.com/docs/en/datapower-operator/1.6)

