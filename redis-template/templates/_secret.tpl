{{- define "redis-template.secret" }}
{{- if .Values.redis.auth.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "redis-template.secretName" . }}
  labels:
    app: {{ .Values.redis.name }}
type: Opaque
data:
  REDIS_PASSWORD: {{ .Values.redis.auth.secret.password | b64enc }}
{{- end }}
{{- end }}