{{- define "redis.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "redis.fullname" . }}-secret
  namespace: {{ .Release.Namespace }}
type: Opaque
data:
  redis-password: {{ .Values.redis.password | b64enc | quote }}
{{- end }}
