# datapower-operator-scripts

Home of utility scripts for automating datapower-operator tasks.

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

## Git hooks

```
cp pre-commit .git/hooks/pre-commit; chmod ug+x .git/hooks/pre-commit
```
