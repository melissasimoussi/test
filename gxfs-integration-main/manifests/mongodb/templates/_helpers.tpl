{{/*
Expand the name of the chart.
*/}}
{{- define "mongodb-operator-databases.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mongodb-operator-databases.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mongodb-operator-databases.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mongodb-operator-databases.labels" -}}
helm.sh/chart: {{ include "mongodb-operator-databases.chart" . }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mongodb-operator-databases.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mongodb-operator-databases.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
