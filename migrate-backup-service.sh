#!/bin/sh

#define parameters which are passed in.
NAME=$1
PORT=$2

#define the template.
cat  << EOF
kind: Service
apiVersion: v1
metadata:
  name: $NAME-service
  namespace: $NAME
spec:
  selector:
    app.kubernetes.io/instance: $NAME-$NAME-migration
  ports:
    - name: mpgw
      protocol: TCP
      port: $PORT
      targetPort: $PORT
EOF