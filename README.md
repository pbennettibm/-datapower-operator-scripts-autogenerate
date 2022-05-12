# datapower-operator-scripts

Home of utility scripts for automating datapower-operator tasks.

## Instuctions

**Pre-Reqs**

1. Config git pre commit hook to run scripts.
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

**Checking in DataPower backup zip files
1. Write git commits after adding DataPower backup zip into the root of this repo.

**Please do not rename any zip files to ensure the git hook works correctly.**
Instead:
1. Move the file out of this repo's directory
2. Add & commit the changes
3. Rename the moved file
4. Move it back to this repo's directory
5. Add & commit the changes.

### Instructions for deploying DataPower on OCS with GitOps

**Pre-reqs**

1.

**Instructions**

1.

### Instructions for deploying DataPower on OCS with GitOps

**Pre-reqs**

1.

**Instructions**

1.

## Debugging

### `must-gather.sh`

Use this script to gather all DataPower Operator related resources from your Kubernetes/OpenShift cluster.

For usage:

```
./must-gather.sh -h
```


Reference:

- [Guide: Domain configuration](https://ibm.github.io/datapower-operator-doc/guides/domain-configuration)
- [DataPowerService API docs](https://ibm.github.io/datapower-operator-doc/apis/datapowerservice/v1beta3)

