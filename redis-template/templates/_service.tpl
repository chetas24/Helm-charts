{{- define "redis-template.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "redis-template.serviceName" . }}
  labels:
    app: {{ .Values.redis.name }}
spec:
  {{- if .Values.redis.service.headless }}
  clusterIP: None
  {{- else }}
  type: {{ .Values.redis.service.type | default "ClusterIP" }}
  {{- end }}
  selector:
    app: {{ .Values.redis.name }}
  ports:
    {{- range .Values.redis.service.ports }}
    - name: {{ .name }}
      port: {{ .port }}
      targetPort: {{ .targetPort | default .port }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
{{- end }}