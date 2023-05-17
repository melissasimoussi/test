{{/*
Namespace from Values or Release Name
*/}}
{{- define "keycloak-operator.ns" -}}
{{- if .Values.namespace }}
{{- .Values.namespace | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}