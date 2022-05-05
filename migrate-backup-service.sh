#!/bin/bash

#define parameters which are passed in.
NAME=$1
PORT=$2

#define the template.
cat  << EOF
kind: Service
apiVersion: v1
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "360"
  name: $NAME-service
  namespace: datapower-instance
spec:
  selector:
    app.kubernetes.io/instance: datapower-instance-$NAME-migration
  ports:
    - name: $NAME-mpgw
      protocol: TCP
      port: $PORT
      targetPort: $PORT
EOF