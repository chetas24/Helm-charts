{{- define "redis-template.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "redis-template.fullname" . }}-config
  namespace: {{ .Release.Namespace }}
data:
  redis.conf: |
{{ .Values.redis.configInline | indent 4 }}
{{- end }}
