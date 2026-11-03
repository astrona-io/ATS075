# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without being run, so the text describes what you should see instead of showing recorded output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-02/labs/lab-01
```

Run `astrona submit --keep` once. Only `backend-requires-auth` passes. It stays your guard: it fails if a fix breaks the backend.

## Step 1: Create the gateway

The gateway receives OTLP from the agents and exports to the backend with the password. The Collector replaces `${env:BACKEND_PASSWORD}` with the value of the environment variable when it loads the file, so the password never appears in the ConfigMap. Save this as `gateway.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-gateway-config
  namespace: starfleet
data:
  config.yaml: |
    extensions:
      health_check:
        endpoint: 0.0.0.0:13133
      basicauth/backend:
        client_auth:
          username: gateway
          password: ${env:BACKEND_PASSWORD}

    receivers:
      otlp:
        protocols:
          http:
            endpoint: 0.0.0.0:4318

    processors:
      memory_limiter:
        check_interval: 1s
        limit_mib: 150
        spike_limit_mib: 30
      batch:

    exporters:
      otlphttp/backend:
        endpoint: http://otel-backend.starfleet.svc:4318
        auth:
          authenticator: basicauth/backend
        sending_queue:
          enabled: true
          queue_size: 5000
        retry_on_failure:
          enabled: true
          initial_interval: 1s
          max_interval: 10s
          max_elapsed_time: 120s

    service:
      extensions: [health_check, basicauth/backend]
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlphttp/backend]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-gateway
  namespace: starfleet
  labels:
    app: otel-gateway
spec:
  replicas: 2
  selector:
    matchLabels:
      app: otel-gateway
  template:
    metadata:
      labels:
        app: otel-gateway
    spec:
      containers:
        - name: collector
          image: otel/opentelemetry-collector-contrib:0.162.0
          args: ["--config=/conf/config.yaml"]
          env:
            - name: BACKEND_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: backend-credentials
                  key: password
          ports:
            - name: otlp-http
              containerPort: 4318
            - name: health
              containerPort: 13133
          readinessProbe:
            httpGet:
              path: /
              port: 13133
          resources:
            requests:
              cpu: 50m
              memory: 128Mi
            limits:
              memory: 256Mi
          volumeMounts:
            - name: conf
              mountPath: /conf
      volumes:
        - name: conf
          configMap:
            name: otel-gateway-config
---
apiVersion: v1
kind: Service
metadata:
  name: otel-gateway
  namespace: starfleet
spec:
  selector:
    app: otel-gateway
  ports:
    - name: otlp-http
      port: 4318
      targetPort: otlp-http
```

Apply it and wait for both replicas:

```sh
kubectl apply -f gateway.yaml
kubectl -n starfleet rollout status deployment/otel-gateway
```

Run `astrona submit --keep`; the checks `gateway-replicas` and `gateway-buffering` should pass.

## Step 2: Point the agent at the gateway and remove its password

Save this as `otel-agent-config.yaml`. The agent keeps its receiver and its protection processors. It loses the `basicauth` extension and the password, and its exporter now points at the gateway:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-agent-config
  namespace: starfleet
data:
  config.yaml: |
    extensions:
      health_check:
        endpoint: 0.0.0.0:13133

    receivers:
      otlp:
        protocols:
          http:
            endpoint: 0.0.0.0:4318

    processors:
      memory_limiter:
        check_interval: 1s
        limit_mib: 150
        spike_limit_mib: 30
      batch:

    exporters:
      otlphttp/gateway:
        endpoint: http://otel-gateway.starfleet.svc:4318

    service:
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlphttp/gateway]
```

Apply it and restart the agent, because the Collector reads the file only at start:

```sh
kubectl apply -f otel-agent-config.yaml
kubectl -n starfleet rollout restart daemonset/otel-agent
kubectl -n starfleet rollout status daemonset/otel-agent
```

## Step 3: Prove it with a request

Send one span from `shuttle`. The status must be `200`:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 -X POST -H 'Content-Type: application/json' -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"demo","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}' http://otel-agent.starfleet.svc:4318/v1/traces
```

Wait a few seconds for the batch, then look for `service.name: Str(scout)` in the backend log:

```sh
kubectl -n starfleet logs deploy/otel-backend --tail=100
```

Search the cluster for the password to confirm that only the Secret and the gateway pods hold it:

```sh
kubectl -n starfleet get configmap,daemonset,deployment -o yaml | grep -c kestrel-orbit-7
```

The count is `0`. Run `astrona submit`; all five checks should pass.

## Why these fixes

The gateway is the only workload that holds the backend password, and it takes the password from a Secret at start. The agents need no password and no route to the backend, so a node that is compromised leaks neither. The sending queue and the retry settings let the gateway hold data while the backend is unavailable, and the memory limiter makes the gateway refuse data before the kernel kills it. Two replicas behind one Service keep the tier available while one pod restarts.
