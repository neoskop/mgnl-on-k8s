{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mgnl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mgnl.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Author instance name
*/}}
{{- define "mgnl.author.name" -}}
{{- printf "%s-author" (include "mgnl.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Public instance name
*/}}
{{- define "mgnl.public.name" -}}
{{- printf "%s-public" (include "mgnl.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Mysql instance name
*/}}
{{- define "mgnl.mysql.name" -}}
{{- printf "%s-mysql" (include "mgnl.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Mysql author host name
*/}}
{{- define "mgnl.mysql.author.host" -}}
{{- default (printf "%s-mysql" (include "mgnl.name" .)) .Values.magnoliaAuthor.datasource.host -}}
{{- end -}}

{{/*
Mysql public host name
*/}}
{{- define "mgnl.mysql.public.host" -}}
{{- default (printf "%s-mysql" (include "mgnl.name" .)) .Values.magnoliaPublic.datasource.host -}}
{{- end -}}

{{/*
Mysql author instance db name
*/}}
{{- define "mgnl.mysql.author.database" -}}
{{- default (printf "%s-author" (include "mgnl.name" .)) .Values.magnoliaAuthor.datasource.database -}}
{{- end -}}

{{/*
Mysql public instance db name
*/}}
{{- define "mgnl.mysql.public.database" -}}
{{- default (printf "%s-public" (include "mgnl.name" .)) .Values.magnoliaPublic.datasource.database -}}
{{- end -}}

{{/*
Mysql author instance user name
*/}}
{{- define "mgnl.mysql.author.user" -}}
{{- default (printf "%s-author" (include "mgnl.name" .)) .Values.magnoliaAuthor.datasource.user -}}
{{- end -}}

{{/*
Mysql public instance user name
*/}}
{{- define "mgnl.mysql.public.user" -}}
{{- default (printf "%s-public" (include "mgnl.name" .)) .Values.magnoliaPublic.datasource.user -}}
{{- end -}}

{{- define "mgnl.magnolia.pullSecrets" -}}
{{- $ := . -}}
{{- $result := dict "secrets" (list) -}}
{{- range list "magnoliaLightModuleUpdater" "magnoliaRuntime" "magnoliaWebapp" "tmpInit" -}}
{{- $pullSecret := (get $.Values .).image.pullSecret -}}
{{- if $pullSecret }}
{{- $noop := printf "{ name: %s }" (printf "%s-%s-pull-secret" (include "mgnl.name" $) (. | lower)) | append $result.secrets | set $result "secrets" -}}
{{- end -}}
{{- end -}}
[{{- join ", " $result.secrets -}}]
{{- end -}}

{{- define "mgnl.mysql.pullSecrets" -}}
{{- $ := . -}}
{{- $result := dict "secrets" (list) -}}
{{- range list "mysql" "mysqlInit" -}}
{{- $pullSecret := (get $.Values .).image.pullSecret -}}
{{- if $pullSecret }}
{{- $noop := printf "{ name: %s }" (printf "%s-%s-pull-secret" (include "mgnl.name" $) (. | lower)) | append $result.secrets | set $result "secrets" -}}
{{- end -}}
{{- end -}}
[{{- join ", " $result.secrets -}}]
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mgnl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mgnl.labels" -}}
helm.sh/chart: {{ include "mgnl.chart" . }}
{{ include "mgnl.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "mgnl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mgnl.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "mgnl.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "mgnl.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
