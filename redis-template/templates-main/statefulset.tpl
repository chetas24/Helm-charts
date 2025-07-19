{{- define "redis-template.statefulset" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "redis-template.fullname" . }}
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    matchLabels:
      app: {{ include "redis-template.fullname" . }}
  serviceName: {{ include "redis-template.fullname" . }}
  replicas: 1
  template:
    metadata:
      labels:
        app: {{ include "redis-template.fullname" . }}
    spec:
      containers:
        - name: redis
          image: "{{ .Values.redis.image.repository }}:{{ .Values.redis.image.tag }}"
          imagePullPolicy: {{ .Values.redis.image.pullPolicy }}
          ports:
            - containerPort: 6379
              name: redis
          env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "redis-template.fullname" . }}-secret
                  key: redis-password
          volumeMounts:
            - name: redis-data
              mountPath: /data
              subPath: data
          livenessProbe:
            tcpSocket:
              port: 6379
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            tcpSocket:
              port: 6379
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              memory: {{ .Values.redis.resources.requests.memory | quote }}
              cpu: {{ .Values.redis.resources.requests.cpu | quote }}
            limits:
              memory: {{ .Values.redis.resources.limits.memory | quote }}
              cpu: {{ .Values.redis.resources.limits.cpu | quote }}
      {{- if not .Values.redis.persistence.enabled }}
      volumes:
        - name: redis-data
          emptyDir: {}
      {{- end }}
  {{- if .Values.redis.persistence.enabled }}
  volumeClaimTemplates:
    - metadata:
        name: redis-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: {{ .Values.redis.persistence.size }}
        storageClassName: {{ .Values.redis.persistence.storageClass | quote }}
  {{- end }}
{{- end }}
