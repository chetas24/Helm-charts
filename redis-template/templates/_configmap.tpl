{{- define "redis-template.configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "redis-template.configmapName" . }}
  labels:
    app: {{ .Values.redis.name }}
data:
  redis.conf: |
    bind {{ .Values.redis.config.bind | default "0.0.0.0" }}
    port {{ .Values.redis.port }}
    maxmemory {{ .Values.redis.config.maxmemory }}
    maxmemory-policy {{ .Values.redis.config.policy }}
    {{- if .Values.redis.auth.enabled }}
    requirepass {{ .Values.redis.auth.secret.password }}
    {{- end }}
    {{- if .Values.redis.persistence.enabled }}
    appendonly yes
    {{- end }}
{{- end }}