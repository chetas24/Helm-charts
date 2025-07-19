{{- define "redis.statefulset" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "redis.fullname" . }}
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    matchLabels:
      app: {{ include "redis.fullname" . }}
  serviceName: {{ include "redis.fullname" . }}
  replicas: 1
  template:
    metadata:
      labels:
        app: {{ include "redis.fullname" . }}
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
                  name: {{ include "redis.fullname" . }}-secret
                  key: redis-password
          volumeMounts:
            - name: redis-data
              mountPath: /data
              subPath: data
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
