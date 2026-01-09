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
{{- define "mgnl.mysql.author.username" -}}
{{- default (printf "%s-author" (include "mgnl.name" .)) .Values.magnoliaAuthor.datasource.username -}}
{{- end -}}

{{/*
Mysql public instance user name
*/}}
{{- define "mgnl.mysql.public.username" -}}
{{- default (printf "%s-public" (include "mgnl.name" .)) .Values.magnoliaPublic.datasource.username -}}
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

{{/*
=============================================================================
Merge helpers for shared magnolia configuration
=============================================================================
*/}}

{{/*
Get effective customEnv for author (merged shared + instance-specific)
Instance-specific values override shared values
*/}}
{{- define "mgnl.author.customEnv" -}}
{{- $shared := .Values.magnolia.customEnv | default dict -}}
{{- $instance := .Values.magnoliaAuthor.customEnv | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective customEnv for public (merged shared + instance-specific)
*/}}
{{- define "mgnl.public.customEnv" -}}
{{- $shared := .Values.magnolia.customEnv | default dict -}}
{{- $instance := .Values.magnoliaPublic.customEnv | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective microprofileConfig for author (merged shared + instance-specific)
*/}}
{{- define "mgnl.author.microprofileConfig" -}}
{{- $shared := .Values.magnolia.microprofileConfig | default dict -}}
{{- $instance := .Values.magnoliaAuthor.microprofileConfig | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective microprofileConfig for public (merged shared + instance-specific)
*/}}
{{- define "mgnl.public.microprofileConfig" -}}
{{- $shared := .Values.magnolia.microprofileConfig | default dict -}}
{{- $instance := .Values.magnoliaPublic.microprofileConfig | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective ingress annotations for author (merged shared + instance-specific)
*/}}
{{- define "mgnl.author.ingress.annotations" -}}
{{- $shared := .Values.magnolia.ingress.annotations | default dict -}}
{{- $instance := .Values.magnoliaAuthor.ingress.annotations | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective ingress annotations for public (merged shared + instance-specific)
*/}}
{{- define "mgnl.public.ingress.annotations" -}}
{{- $shared := .Values.magnolia.ingress.annotations | default dict -}}
{{- $instance := .Values.magnoliaPublic.ingress.annotations | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective ingress labels for author (merged shared + instance-specific)
*/}}
{{- define "mgnl.author.ingress.labels" -}}
{{- $shared := .Values.magnolia.ingress.labels | default dict -}}
{{- $instance := .Values.magnoliaAuthor.ingress.labels | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective ingress labels for public (merged shared + instance-specific)
*/}}
{{- define "mgnl.public.ingress.labels" -}}
{{- $shared := .Values.magnolia.ingress.labels | default dict -}}
{{- $instance := .Values.magnoliaPublic.ingress.labels | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective assetIngress annotations for author (merged shared + instance-specific)
*/}}
{{- define "mgnl.author.assetIngress.annotations" -}}
{{- $shared := .Values.magnolia.assetIngress.annotations | default dict -}}
{{- $instance := .Values.magnoliaAuthor.assetIngress.annotations | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective assetIngress annotations for public (merged shared + instance-specific)
*/}}
{{- define "mgnl.public.assetIngress.annotations" -}}
{{- $shared := .Values.magnolia.assetIngress.annotations | default dict -}}
{{- $instance := .Values.magnoliaPublic.assetIngress.annotations | default dict -}}
{{- merge $instance $shared | toYaml -}}
{{- end -}}

{{/*
Get effective nodeSelector for author
Returns instance-specific if non-empty, otherwise shared
*/}}
{{- define "mgnl.author.nodeSelector" -}}
{{- if .Values.magnoliaAuthor.nodeSelector -}}
{{- toYaml .Values.magnoliaAuthor.nodeSelector -}}
{{- else -}}
{{- toYaml (.Values.magnolia.nodeSelector | default dict) -}}
{{- end -}}
{{- end -}}

{{/*
Get effective nodeSelector for public
*/}}
{{- define "mgnl.public.nodeSelector" -}}
{{- if .Values.magnoliaPublic.nodeSelector -}}
{{- toYaml .Values.magnoliaPublic.nodeSelector -}}
{{- else -}}
{{- toYaml (.Values.magnolia.nodeSelector | default dict) -}}
{{- end -}}
{{- end -}}

{{/*
Get effective tolerations for author
*/}}
{{- define "mgnl.author.tolerations" -}}
{{- if .Values.magnoliaAuthor.tolerations -}}
{{- toYaml .Values.magnoliaAuthor.tolerations -}}
{{- else -}}
{{- toYaml (.Values.magnolia.tolerations | default list) -}}
{{- end -}}
{{- end -}}

{{/*
Get effective tolerations for public
*/}}
{{- define "mgnl.public.tolerations" -}}
{{- if .Values.magnoliaPublic.tolerations -}}
{{- toYaml .Values.magnoliaPublic.tolerations -}}
{{- else -}}
{{- toYaml (.Values.magnolia.tolerations | default list) -}}
{{- end -}}
{{- end -}}

{{/*
Get effective affinity for author
*/}}
{{- define "mgnl.author.affinity" -}}
{{- if .Values.magnoliaAuthor.affinity -}}
{{- toYaml .Values.magnoliaAuthor.affinity -}}
{{- else -}}
{{- toYaml (.Values.magnolia.affinity | default dict) -}}
{{- end -}}
{{- end -}}

{{/*
Get effective affinity for public
*/}}
{{- define "mgnl.public.affinity" -}}
{{- if .Values.magnoliaPublic.affinity -}}
{{- toYaml .Values.magnoliaPublic.affinity -}}
{{- else -}}
{{- toYaml (.Values.magnolia.affinity | default dict) -}}
{{- end -}}
{{- end -}}

{{/*
Get effective datasource port for author
*/}}
{{- define "mgnl.author.datasource.port" -}}
{{- if .Values.magnoliaAuthor.datasource.port -}}
{{- .Values.magnoliaAuthor.datasource.port -}}
{{- else -}}
{{- .Values.magnolia.datasource.port | default 3306 -}}
{{- end -}}
{{- end -}}

{{/*
Get effective datasource port for public
*/}}
{{- define "mgnl.public.datasource.port" -}}
{{- if .Values.magnoliaPublic.datasource.port -}}
{{- .Values.magnoliaPublic.datasource.port -}}
{{- else -}}
{{- .Values.magnolia.datasource.port | default 3306 -}}
{{- end -}}
{{- end -}}
