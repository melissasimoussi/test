{{- define "app.mongodb-hook" }}
{{ $mongodbPassword := randAlphaNum 24 }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "app.name" . }}
  namespace: {{ .Release.Namespace }}
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  ttlSecondsAfterFinished: 600
  template:
    metadata:
      name: "{{ .Release.Name }}"
      labels:
        {{- include "app.labels" . | nindent 8 }}
    spec:
      restartPolicy: Never
      containers:
      - name: pre-install-job
        image: "debian:buster-slim"
        env:
          - name: MONGODB_DATABASE_NAME
            value:  {{ .Values.mongodb.database | quote }}
          - name: MONGODB_USERNAME
            {{- if and (.Values.mongodb.passwordSecret) (.Values.mongodb.usernameSecret) }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.mongodb.usernameSecret.name | quote }}
                key: {{ .Values.mongodb.usernameSecret.key | quote }}
            {{- else }}
            value: {{ .Values.mongodb.username | quote }}
            {{- end }}
          - name: MONGODB_USER_PASSWORD
            {{- if and (.Values.mongodb.passwordSecret) (.Values.mongodb.usernameSecret) }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.mongodb.passwordSecret.name | quote }}
                key: {{ .Values.mongodb.passwordSecret.key | quote }}
            {{- else }}
            value: {{ $mongodbPassword | quote }}
            {{- end }}
          - name: MONGODB_URI
            {{- if .Values.mongodb.uriSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.mongodb.uriSecret.name }}
                key: {{ .Values.mongodb.uriSecret.key }}
            {{- else }}
            value: {{ .Values.mongodb.uri | quote }}
            {{- end }}
          - name: MONGODB_SUPERUSER_USERNAME
            {{- if .Values.mongodb.superUser.usernameSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.mongodb.superUser.usernameSecret.name }}
                key: {{ .Values.mongodb.superUser.usernameSecret.key }}
            {{- else }}
            value: {{ .Values.mongodb.superUser.username | quote }}
            {{- end }}
          - name: MONGODB_SUPERUSER_PASSWORD
            {{- if .Values.mongodb.superUser.passwordSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.mongodb.superUser.passwordSecret.name }}
                key: {{ .Values.mongodb.superUser.passwordSecret.key }}
            {{- else }}
            value: {{ .Values.mongodb.superUser.password | quote }}
            {{- end }}
          - name: MONGODB_AUTHENTICATION_MECHANISM
            value: {{ .Values.mongodb.authenticationMechanism | default "SCRAM-SHA-256" | quote }}
        command:
          - /bin/sh
          - -c
          - |
            set -e
            apt-get update && apt-get install -y wget gnupg -y
            wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
            echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
            apt-get update
            apt-get install -y mongodb-org=4.4.15 mongodb-org-server=4.4.15 mongodb-org-shell=4.4.15 mongodb-org-mongos=4.4.15 mongodb-org-tools=4.4.15

            # check if user exists
            if mongo --quiet $MONGODB_URI --username "$MONGODB_SUPERUSER_USERNAME" --password "$MONGODB_SUPERUSER_PASSWORD" --eval "db.system.users.find({user: '$MONGODB_USERNAME'}).count()" | grep -q -Fx 1; then
              echo "User \"$MONGODB_USERNAME\" already exists"
              # update user
              echo "Updating user \"$MONGODB_USERNAME\""
              mongo $MONGODB_URI --username "$MONGODB_SUPERUSER_USERNAME" --password "$MONGODB_SUPERUSER_PASSWORD" --eval "db.updateUser('$MONGODB_USERNAME', { pwd: '$MONGODB_USER_PASSWORD', passwordDigestor: 'server', roles: [ { role: 'readWrite', db: '$MONGODB_DATABASE_NAME' } ], mechanisms: [ '$MONGODB_AUTHENTICATION_MECHANISM' ] })"
            elif mongo -quiet $MONGODB_URI --username "$MONGODB_SUPERUSER_USERNAME" --password "$MONGODB_SUPERUSER_PASSWORD" --eval "db.system.users.find({user: '$MONGODB_USERNAME'}).count()" | grep -q -Fx 0; then
              echo "Creating user \"$MONGODB_USERNAME\""
              mongo $MONGODB_URI --username "$MONGODB_SUPERUSER_USERNAME" --password "$MONGODB_SUPERUSER_PASSWORD" --authenticationMechanism "$MONGODB_AUTHENTICATION_MECHANISM" --eval "db.createUser({user: '$MONGODB_USERNAME', pwd: '$MONGODB_USER_PASSWORD', roles: [{role: 'readWrite', db: '$MONGODB_DATABASE_NAME'}], mechanisms: [ '$MONGODB_AUTHENTICATION_MECHANISM' ]})"
            else
              echo "Error: Could not check if user \"$MONGODB_USERNAME\" exists"
              exit 1
            fi
---
{{- if or (not .Values.mongodb.usernameSecret) (not .Values.mongodb.passwordSecret) }}
kind: Secret
apiVersion: v1
metadata:
  name: {{ include "app.fullname" . }}
type: Opaque
data:
  mongodb-username: {{ .Values.mongodb.username | b64enc | quote }}
  mongodb-password: {{ $mongodbPassword | b64enc | quote }}
{{- end }}
{{- end -}}
