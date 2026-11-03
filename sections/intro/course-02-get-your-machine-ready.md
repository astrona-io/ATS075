# Get Your Machine Ready

You need the Astrona command-line tool, `astrona`, and a container engine that can run kind (Kubernetes in Docker), such as Docker or Podman. kind creates a single-node Kubernetes cluster inside a container. You also need `kubectl`, the Kubernetes command-line client, and `jq`, a tool that filters JSON. Each playground and lab needs about 2 GiB of free memory.

Check the tool with `astrona check`. Start an environment with `astrona run`, check a graded lab with `astrona submit`, and remove an environment with `astrona destroy` followed by the environment name. The page that opens a playground or lab shows the exact commands for it.

The Collector image `otel/opentelemetry-collector-contrib` is loaded into the cluster when an environment starts. If a start fails, run `astrona destroy` for the environment, check that the container engine is running and has enough memory, and start again.

The course uses Mermaid diagrams, a text format that the reading interface turns into drawings. If your reader does not display a diagram, the surrounding prose still explains its mechanism. The labs in this course are marked as built but not yet run end to end. If a lab check behaves differently from its task text, report the lab name and the failing check.
