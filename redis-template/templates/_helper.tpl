{{- define "redis-template.fullname" -}}
{{ printf "%s-%s" .Release.Name .Values.redis.name }}
{{- end }}

{{- define "redis-template.configmapName" -}}
{{ default (printf "%s-%s-config" .Release.Name .Values.redis.name) .Values.redis.configMapName }}
{{- end }}

{{- define "redis-template.secretName" -}}
{{ default (printf "%s-%s-secret" .Release.Name .Values.redis.name) .Values.redis.auth.secretName }}
{{- end }}

{{- define "redis-template.serviceName" -}}
{{ default (printf "%s-%s-service" .Release.Name .Values.redis.name) .Values.redis.serviceName }}
{{- end }}

{{- define "redis-template.pvcName" -}}
{{ default (printf "%s-%s-pvc" .Release.Name .Values.redis.name) .Values.redis.pvcName }}
{{- end }}
