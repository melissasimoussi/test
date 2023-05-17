{{- define "app.postgres-hook" }}
{{ $postgresPassword := randAlphaNum 24 }}
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
  ttlSecondsAfterFinished: 100
  template:
    metadata:
      name: "{{ .Release.Name }}"
      labels:
        {{- include "app.labels" . | nindent 8 }}
    spec:
      restartPolicy: Never
      containers:
      - name: pre-install-job
        image: "postgres:9.6"
        env:
          - name: POSTGRES_DATABASE_NAME
            value:  {{ .Values.postgres.database | quote }}
          - name: POSTGRES_USERNAME
            {{- if and (.Values.postgres.passwordSecret) (.Values.postgres.usernameSecret) }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.postgres.usernameSecret.name | quote }}
                key: {{ .Values.postgres.usernameSecret.key | quote }}
            {{- else }}
            value: {{ .Values.postgres.username | quote }}
            {{- end }}
          - name: POSTGRES_USER_PASSWORD
            {{- if and (.Values.postgres.passwordSecret) (.Values.postgres.usernameSecret) }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.postgres.passwordSecret.name | quote }}
                key: {{ .Values.postgres.passwordSecret.key | quote }}
            {{- else }}
            value: {{ $postgresPassword | quote }}
            {{- end }}
          - name: POSTGRES_HOST
            value: {{ .Values.postgres.host.name }}
          - name: POSTGRES_PORT
            value: {{ .Values.postgres.host.port | quote }}
          - name: POSTGRES_SUPERUSER_USERNAME
            {{- if .Values.postgres.superUser.usernameSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.postgres.superUser.usernameSecret.name }}
                key: {{ .Values.postgres.superUser.usernameSecret.key }}
            {{- else }}
            value: {{ .Values.postgres.superUser.username | quote }}
            {{- end }}
          - name: POSTGRES_SUPERUSER_PASSWORD
            {{- if .Values.postgres.superUser.passwordSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.postgres.superUser.passwordSecret.name }}
                key: {{ .Values.postgres.superUser.passwordSecret.key }}
            {{- else }}
            value: {{ .Values.postgres.superUser.password | quote }}
            {{- end }}
          - name: SCHEMA
            value: {{ .Values.postgres.schema | default "public" | quote }}
        command:
          - /bin/sh
          - -c
          - |
            set -e
            export PGPASSWORD="$POSTGRES_SUPERUSER_PASSWORD"
            # check if user exists
            if psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -tXAc "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USERNAME'" | grep -q 1; then
              echo "User \"$POSTGRES_USERNAME\" already exists"
              # change user password
              psql -h "$POSTGRES_HOST" -U "$POSTGRES_SUPERUSER_USERNAME" -c "ALTER USER \"$POSTGRES_USERNAME\" WITH PASSWORD '$POSTGRES_USER_PASSWORD';"
            else
              echo "Creating user \"$POSTGRES_USERNAME\""
              psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -c "CREATE USER \"$POSTGRES_USERNAME\" WITH PASSWORD '$POSTGRES_USER_PASSWORD';"
            fi

            # check if database exists
            if psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -tXAc "SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DATABASE_NAME'" | grep -q 1; then
              echo "Database \"$POSTGRES_DATABASE_NAME\" already exists"
            else
              echo "Creating database \"$POSTGRES_DATABASE_NAME\""
              psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -c "CREATE DATABASE \"$POSTGRES_DATABASE_NAME\";"
            fi

            # check if schema exists
            if psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -d "$POSTGRES_DATABASE_NAME" -tXAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='$SCHEMA'" | grep -q 1; then
              echo "Schema \"$SCHEMA\" already exists"
            else
              echo "Creating schema \"$SCHEMA\""
              psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -d "$POSTGRES_DATABASE_NAME" -c "CREATE SCHEMA \"$SCHEMA\";"
            fi

            # grant user access to database and schema
            psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -c "GRANT ALL PRIVILEGES ON DATABASE \"$POSTGRES_DATABASE_NAME\" TO \"$POSTGRES_USERNAME\";"
            psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -d "$POSTGRES_DATABASE_NAME" -c "GRANT ALL PRIVILEGES ON SCHEMA \"$SCHEMA\" TO \"$POSTGRES_USERNAME\";"
            psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_SUPERUSER_USERNAME" -d "$POSTGRES_DATABASE_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA \"$SCHEMA\" TO \"$POSTGRES_USERNAME\";"

---
{{- if or (not .Values.postgres.usernameSecret) (not .Values.postgres.passwordSecret) }}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (include "app.fullname" .) }}
kind: Secret
apiVersion: v1
metadata:
  name: {{ include "app.fullname" . }}
type: Opaque
data:
{{- if $secret }}
  postgres-username: {{ index $secret.data "postgres-username" }}
  postgres-password: {{ index $secret.data "postgres-password" }}
{{- else }}
  postgres-username: {{ .Values.postgres.username | b64enc | quote }}
  postgres-password: {{ $postgresPassword | b64enc | quote }}
{{- end }}
{{- end }}
{{- end -}}