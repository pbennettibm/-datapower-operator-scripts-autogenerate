# datapower-operator-scripts

Home of utility scripts for automating datapower-operator tasks.

## Add git pre commit hook for `migrate-backup.sh`

```
git config core.hooksPath .githooks
```

### Then depending on your OS:

- Mac

```
chmod ug+x .githooks/pre-commit migrate-backup-dps.sh migrate-backup-route.sh migrate-backup-service.sh
```

- Windows

```
icacls .githooks/pre-commit migrate-backup-dps.sh migrate-backup-route.sh migrate-backup-service.sh /grant *S-1-1-0:F
```

_Note: You may have to use the full path on Windows to correctly authorize the hook to run. We haven't had the ability to test this yet._

### Please do not rename any zip files to ensure the git hook works correctly.

Instead:

1. Move the file out of this repo's directory
2. Commit the changes
3. Rename the moved file
4. Move it back to this repo's directory
5. Commit the changes

## `must-gather.sh`

Use this script to gather all DataPower Operator related resources from your Kubernetes/OpenShift cluster.

For usage:

```
./must-gather.sh -h
```

## `migrate-backup.sh`

Use this script to migrate an IBM DataPower Gateway backup ZIP to ConfigMaps for use in DataPowerService deployments.

For usage:

```
./migrate-backup.sh -h
```

Reference:

- [Guide: Domain configuration](https://ibm.github.io/datapower-operator-doc/guides/domain-configuration)
- [DataPowerService API docs](https://ibm.github.io/datapower-operator-doc/apis/datapowerservice/v1beta3)
