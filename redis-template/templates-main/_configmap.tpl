{{- define "redis.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "redis.fullname" . }}-config
  namespace: {{ .Release.Namespace }}
data:
  redis.conf: |
    maxmemory 2mb
    maxmemory-policy allkeys-lru
{{- end }}
