{{- define "redis-template.fullname" -}}
{{ .Release.Name }}-{{ .Values.redis.name }}
{{- end }}

{{- define "redis-template.configmapName" -}}
{{ .Release.Name }}-{{ .Values.redis.name }}-config
{{- end }}

{{- define "redis-template.secretName" -}}
{{ .Release.Name }}-{{ .Values.redis.name }}-secret
{{- end }}
