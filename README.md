# datapower-operator-scripts

Home of utility scripts for automating datapower-operator tasks.

## Add git pre commit hook for `migrate-backup.sh`

```
git config core.hooksPath .githooks
```

# Then Depending on your OS:

Mac
```
chmod ug+x .githooks/pre-commit
```

Windows
```
icacls .githooks/pre-commit /grant *S-1-1-0:F
```
Note: You may have to use the full path on Windows to correctly authorize the hook to run.  We haven't had the ability to test this yet.

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
