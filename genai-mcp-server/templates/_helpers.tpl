{{/*
Release name. Prefer .Values.appname so the CI values files (which already carry
appname per workload, e.g. data-context-layer vs data-context-layer-worker) stay
the single source of truth for the object names.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.appname | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.fullname" -}}
{{- include "app.name" . -}}
{{- end -}}

{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Container/service port name for an entry of .Values.extraServices. Kubernetes caps
port names at 15 chars, so derive one from the number instead of the service name.
*/}}
{{- define "app.portName" -}}
{{- .portName | default (printf "port-%v" (.targetPort | default .port)) -}}
{{- end -}}

{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "app.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Full image reference. CI injects image.repository/image.tag at deploy time;
image.registry is kept separate so a mirror can be swapped without touching tags.
*/}}
{{- define "app.image" -}}
{{- $registry := .Values.image.registry | default "" -}}
{{- $repo := required "image.repository is required" .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion | default "latest" -}}
{{- if $registry -}}
{{ printf "%s/%s:%s" $registry $repo $tag }}
{{- else -}}
{{ printf "%s:%s" $repo $tag }}
{{- end -}}
{{- end -}}
