{{- define "app.redis-hook" }}
{{ $redisPassword := randAlphaNum 24 }}
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
        image: "bitnami/redis:6.2.7"
        env:
          - name: REDIS_DATABASE_NAME
            value:  {{ .Values.redis.database | quote }}
          - name: REDIS_USERNAME
            {{- if and (.Values.redis.passwordSecret) (.Values.redis.usernameSecret) }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.redis.usernameSecret.name | quote }}
                key: {{ .Values.redis.usernameSecret.key | quote }}
            {{- else }}
            value: {{ .Values.redis.username | quote }}
            {{- end }}
          - name: REDIS_USER_PASSWORD
            {{- if and (.Values.redis.passwordSecret) (.Values.redis.usernameSecret) }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.redis.passwordSecret.name | quote }}
                key: {{ .Values.redis.passwordSecret.key | quote }}
            {{- else }}
            value: {{ $redisPassword | quote }}
            {{- end }}
          - name: REDIS_HOST
            value: {{ .Values.redis.host.name }}
          - name: REDIS_PORT
            value: {{ .Values.redis.host.port | quote }}
          - name: REDIS_SUPERUSER_PASSWORD
            {{- if .Values.redis.superUser.passwordSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ .Values.redis.superUser.passwordSecret.name }}
                key: {{ .Values.redis.superUser.passwordSecret.key }}
            {{- else }}
            value: {{ .Values.redis.superUser.password | quote }}
            {{- end }}
        command:
          - /bin/bash
          - -c
          - |
            set -e
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a "$REDIS_SUPERUSER_PASSWORD" ACL SETUSER $REDIS_USERNAME reset
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a "$REDIS_SUPERUSER_PASSWORD" ACL SETUSER $REDIS_USERNAME on \>$REDIS_USER_PASSWORD +@all ~* -select +select\|$REDIS_DATABASE_NAME

---
{{- if or (not .Values.redis.usernameSecret) (not .Values.redis.passwordSecret) }}
kind: Secret
apiVersion: v1
metadata:
  name: {{ include "app.fullname" . }}
type: Opaque
data:
  redis-username: {{ .Values.redis.username | b64enc | quote }}
  redis-password: {{ $redisPassword | b64enc | quote }}
{{- end }}
{{- end -}}