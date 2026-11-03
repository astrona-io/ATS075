# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without being run, so the text describes what you should see instead of showing recorded output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS075.git -c sections/section-020/module-01/labs/lab-01
```

Run `astrona submit --keep` once. All four checks fail, because the agent adds nothing yet.

## Step 1: Give the agent read-only access

The `k8sattributes` processor asks the Kubernetes API server which pod owns an address. It needs `get`, `list` and `watch` on pods and namespaces. Save this as `rbac-otel-agent.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-agent
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: otel-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: otel-agent
subjects:
  - kind: ServiceAccount
    name: otel-agent
    namespace: starfleet
```

Apply it:

```sh
kubectl apply -f rbac-otel-agent.yaml
```

Then check one allowed and one forbidden action:

```sh
kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:starfleet:otel-agent
kubectl auth can-i get secrets --all-namespaces --as=system:serviceaccount:starfleet:otel-agent
```

The first command prints `yes` and the second prints `no`. Run `astrona submit --keep`; the check `agent-rbac` should pass.

## Step 2: Add the node name to the agent container

The processor filter reads the node name from an environment variable that the Kubernetes API fills from the pod field `spec.nodeName`. The same patch adds the variable for the next step. Save this as `patch-agent-env.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: collector
          env:
            - name: KUBE_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: OTEL_RESOURCE_ATTRIBUTES
              value: deployment.environment.name=lab
```

Apply it:

```sh
kubectl -n starfleet patch daemonset otel-agent --patch-file patch-agent-env.yaml
```

The patch changes the pod template, so the DaemonSet rolls out new pods.

## Step 3: Write the complete agent configuration

Save this as `otel-agent-config.yaml`. It keeps the receiver and exporter, and adds the processors and the metrics pipeline:

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
      hostmetrics:
        collection_interval: 10s
        scrapers:
          load:
          memory:

    processors:
      memory_limiter:
        check_interval: 1s
        limit_mib: 150
        spike_limit_mib: 30
      k8sattributes:
        filter:
          node_from_env_var: KUBE_NODE_NAME
        extract:
          metadata:
            - k8s.namespace.name
            - k8s.pod.name
            - k8s.node.name
            - k8s.deployment.name
        pod_association:
          - sources:
              - from: connection
      resourcedetection:
        detectors: [env, system]
        timeout: 2s
        override: false

    exporters:
      debug:
        verbosity: detailed

    service:
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, k8sattributes, resourcedetection]
          exporters: [debug]
        metrics:
          receivers: [hostmetrics]
          processors: [memory_limiter, resourcedetection]
          exporters: [debug]
```

Apply it and restart the agent, because the Collector reads the file only at start:

```sh
kubectl apply -f otel-agent-config.yaml
kubectl -n starfleet rollout restart daemonset/otel-agent
kubectl -n starfleet rollout status daemonset/otel-agent
```

## Step 4: Prove it with a request

Send one span from `shuttle`. The status must be `200`:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 -X POST -H 'Content-Type: application/json' -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"scout"}}]},"scopeSpans":[{"scope":{"name":"manual"},"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"demo","kind":2,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}' http://otel-agent.starfleet.svc:4318/v1/traces
```

Read the agent output. Look for `k8s.pod.name`, `k8s.node.name`, `deployment.environment.name` and `service.name: Str(scout)` in the resource attributes, and for the metric `system.cpu.load_average.1m`:

```sh
kubectl -n starfleet logs -l app=otel-agent --tail=200
```

Run `astrona submit`; all four checks should pass.

## Why these fixes

The agent sees each request on a node. The `k8sattributes` processor turns the source address of the connection into a pod and adds the pod's metadata, which only works if the API server allows the lookup and if the lookup is limited to the node. The `env` detector adds attributes that the platform team sets once per agent. With `override: false` the detector never replaces a value that the application set. The `hostmetrics` receiver adds node-level measurements, and the `system` detector labels them with the host name.
