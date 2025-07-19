{{- define "redis.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "redis.fullname" . }}
  namespace: {{ .Release.Namespace }}
spec:
  type: {{ .Values.redis.service.type }}
  ports:
    - port: {{ .Values.redis.service.port }}
      targetPort: 6379
      name: redis
  selector:
    app: {{ include "redis.fullname" . }}
{{- end }}
