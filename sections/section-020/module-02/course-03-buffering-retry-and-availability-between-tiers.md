---
draft: true
exam_objectives:
  - Deployment
---
# Buffering, Retry And Availability Between Tiers

A second tier adds a network hop, and every hop can fail. The backend can be down for a deployment, a gateway pod can restart, and a burst can be larger than the gateway can process. The Collector has three tools for this: a queue that holds data, a retry policy that sends it again, and a memory limit that refuses data before the process fails. This part explains how they work together, what they cannot protect, and how replicas change the picture.

## The exporter queue and retry

Every exporter built on the common exporter helper, including `otlphttp`, has two settings that matter here.

The `sending_queue` is a buffer between the pipeline and the network call. The pipeline places a batch in the queue and continues, while worker threads take batches out and send them. The option `queue_size` limits the queue in requests, and `enabled: true` turns it on. When the queue is full, new data is refused, and the refusal travels back to the sender as an error.

The `retry_on_failure` setting controls what happens when a send fails with an error that is worth retrying. The exporter waits `initial_interval`, then doubles the wait up to `max_interval`, and gives up for that batch after `max_elapsed_time`. A batch that is given up is dropped, and the Collector logs it.

Two facts decide how much protection this gives. First, the default queue lives in memory. A batch in the queue is acknowledged to the sender as soon as it is queued, so if the gateway pod stops, the data in its queue is lost and the agent has no way to know. A persistent queue stores batches in a file through a `storage` extension, which survives a restart if the file stays on a volume. This part describes it and does not build it. Second, the retry time is finite. A backend outage that lasts longer than `max_elapsed_time` loses the data that was waiting.

## memory_limiter and back-pressure

The queue uses memory, and memory is bounded by the container limit. The `memory_limiter` processor at the front of the pipeline keeps the process below its limit by refusing data when use is high. A refused request returns a retryable error to the sender. If the sender is an agent, its own queue and retry hold the data and try again. This is back-pressure: the load moves back towards the sources, where there is a buffer, and not forward into a process that cannot take it. Without the limiter, the same overload would end with the kernel stopping the pod and the loss of everything in memory.

```mermaid
flowchart LR
    A["agent queue and retry"] -->|"OTLP"| M["gateway memory_limiter"]
    M --> Q["gateway sending queue"]
    Q -->|"retry with backoff"| B["backend"]
    B -.->|"error"| Q
    M -.->|"refuse when full"| A
```

The diagram shows the two places where data waits, the agent and the gateway, and the refusal that pushes load back to the previous tier.

## Replicas and availability

One gateway pod is a single point of failure for every agent. With two or more replicas, the Service has several endpoints, and a pod that stops is removed from the list once its readiness probe fails or the pod is deleted. An agent that sends a new request reaches a replica that is still ready. A rolling update replaces replicas one at a time, so the Service always has endpoints during a change. Set the replica count from the load you expect and from the number of failures you want to survive, and keep the memory limit of each pod above the limit of the processor.

Two behaviours of the connection matter for balancing:

- A Kubernetes Service balances connections, not requests. With OTLP over gRPC, a client keeps one long connection, so one agent can stay on one replica for a long time and the load is uneven. OTLP over HTTP usually opens connections more often and spreads better, and a load balancer that understands gRPC can solve the problem for gRPC.
- Some processing needs all data of one trace on the same Collector, for example tail sampling, which decides after it has seen a whole trace. A plain Service does not guarantee that. That case needs a routing step by trace ID in front, and it is a reason to keep it out of a simple gateway.

## Set up the tiers with a queue

Save both tiers as `tiers.yaml`. The gateway exporter gets an explicit queue of 5000 requests and a retry limit of 120 seconds. The agent sends to the gateway as before:

<!-- astrona:playground:renew -->

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
---
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

Apply it and restart the agent, so that both tiers run the new configuration:

```sh
kubectl apply -f tiers.yaml
kubectl -n starfleet rollout status deployment/otel-gateway
kubectl -n starfleet rollout restart daemonset/otel-agent
kubectl -n starfleet rollout status daemonset/otel-agent
```

## Stop the backend and send data

Stop the backend, then send three spans through the agent, with a different `service.name` each time:

```sh
kubectl -n starfleet scale deployment/otel-backend --replicas=0
for name in scout probe drifter; do
  kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 \
    -X POST -H 'Content-Type: application/json' \
    -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"'"$name"'"}}]},"scopeSpans":[{"scope":{"name":"reading"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"demo","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}' \
    http://otel-agent.starfleet.svc:4318/v1/traces
done
```

The agent should answer `200` each time, because its own hop to the gateway works. The failure is one tier further. Wait about twenty seconds and read the gateway logs. Look for lines from the exporter that say a send failed and will be retried, with the name of the backend endpoint:

```sh
kubectl -n starfleet logs -l app=otel-gateway --tail=40 --prefix
```

Now start the backend again, within the retry limit of 120 seconds, and read its output. The queued batches should be delivered with the next successful retry, so the three service names should appear in the backend log:

```sh
kubectl -n starfleet scale deployment/otel-backend --replicas=1
kubectl -n starfleet rollout status deployment/otel-backend
kubectl -n starfleet logs deploy/otel-backend --tail=80
```

If you wait longer than the retry limit, the batches are dropped, and the log of the gateway says so. Repeat the experiment with a pod deletion in place of the backend stop: delete one gateway pod with `kubectl -n starfleet delete pod -l app=otel-gateway --wait=false` while you send spans, and compare. New requests go to the pod that is still ready, but the batches that were in the queue of the deleted pod are gone.

## Common pitfalls

> [!WARNING]
> A queue and a retry policy are not a guarantee. The default queue is in memory, so a gateway pod that stops loses what it holds, and a backend outage longer than `max_elapsed_time` drops data. Do not set a huge `queue_size` to hide an unreliable backend: the queue then uses memory that `memory_limiter` and the container limit will refuse, and the process may be stopped. Run at least two gateway replicas, keep the limiter first in the pipeline, and treat a persistent queue on a volume as the next step when loss is not acceptable.
