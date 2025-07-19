{{- define "redis-template.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "redis-template.fullname" . }}-secret
  namespace: {{ .Release.Namespace }}
type: Opaque
data:
  redis-password: {{ .Values.redis.password | b64enc | quote }}
{{- end }}
