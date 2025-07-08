{{- define "redis-template.statefulset" }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "redis-template.fullname" . }}
  labels:
    app: {{ .Values.redis.name }}
spec:
  serviceName: {{ include "redis-template.serviceName" . }}
  replicas: {{ .Values.redis.replicas | default 1 }}
  selector:
    matchLabels:
      app: {{ .Values.redis.name }}
  updateStrategy:
    type: {{ .Values.redis.updateStrategy | default "RollingUpdate" }}
  template:
    metadata:
      labels:
        app: {{ .Values.redis.name }}
    spec:
      terminationGracePeriodSeconds: {{ .Values.redis.terminationGracePeriodSeconds | default 10 }}
      securityContext:
        runAsUser: {{ .Values.redis.securityContext.runAsUser | default 1000 }}
        runAsGroup: {{ .Values.redis.securityContext.runAsGroup | default 1000 }}
        fsGroup: {{ .Values.redis.securityContext.fsGroup | default 1000 }}
      containers:
        - name: {{ .Values.redis.name }}
          image: "{{ .Values.redis.image.repository }}:{{ .Values.redis.image.tag }}"
          imagePullPolicy: {{ .Values.redis.image.pullPolicy | default "IfNotPresent" }}
          ports:
            - containerPort: {{ .Values.redis.port | default 6379 }}
              name: redis
          command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
          env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "redis-template.secretName" . }}
                  key: REDIS_PASSWORD
          volumeMounts:
            - name: redis-config
              mountPath: /usr/local/etc/redis
            {{- if .Values.redis.persistence.enabled }}
            - name: data
              mountPath: /data
            {{- end }}
          resources:
            limits:
              cpu: {{ .Values.redis.resources.limits.cpu | default "500m" }}
              memory: {{ .Values.redis.resources.limits.memory | default "512Mi" }}
            requests:
              cpu: {{ .Values.redis.resources.requests.cpu | default "100m" }}
              memory: {{ .Values.redis.resources.requests.memory | default "256Mi" }}
          securityContext:
            readOnlyRootFilesystem: {{ .Values.redis.containerSecurityContext.readOnlyRootFilesystem | default false }}
            allowPrivilegeEscalation: {{ .Values.redis.containerSecurityContext.allowPrivilegeEscalation | default false }}
            capabilities:
              drop:
                {{- range .Values.redis.containerSecurityContext.capabilities.drop }}
                - {{ . }}
                {{- end }}
          livenessProbe:
            exec:
              command: ["redis-cli", "-a", "$(REDIS_PASSWORD)", "ping"]
            initialDelaySeconds: 10
            periodSeconds: 5
          readinessProbe:
            exec:
              command: ["redis-cli", "-a", "$(REDIS_PASSWORD)", "ping"]
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: redis-config
          configMap:
            name: {{ include "redis-template.configmapName" . }}
        {{- if not .Values.redis.persistence.enabled }}
        - name: data
          emptyDir: {}
        {{- end }}
  {{- if .Values.redis.persistence.enabled }}
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: {{ toYaml .Values.redis.persistence.accessModes | nindent 10 }}
        resources:
          requests:
            storage: {{ .Values.redis.persistence.size | quote }}
        {{- if .Values.redis.persistence.storageClassName }}
        storageClassName: {{ .Values.redis.persistence.storageClassName }}
        {{- end }}
  {{- end }}
{{- end }}