# The OpenTelemetry Collector (ATS075)

OpenTelemetry Certified Associate (OTCA): The OpenTelemetry Collector, worth 26% of the official curriculum. This course belongs to ATP015.

The course has readings that explain mechanisms, a playground and a graded lab for every module, a capstone lab for every section, a quiz for every section and a final quiz. Labs run on kind (Kubernetes 1.35) with the Collector contrib image. They are built untested: static checks only. Technical content remains draft.

## Course Outline

| Section / module | Module |
| --- | --- |
| 010 / 01 | Component Definitions And Enabled Pipelines |
| 010 / 02 | Configuration Sources, Environment Values And Extensions |
| 020 / 01 | Agent Deployment Patterns |
| 020 / 02 | Gateway Deployment And Agent-To-Gateway Export |
| 030 / 01 | Capacity Signals And Protecting The Collector |
| 030 / 02 | Sharding And Stateful Processing |
| 040 / 01 | Signal Paths, Shared Components And Fan-Out |
| 040 / 02 | Connectors, Backpressure And Failure Behavior |
| 050 / 01 | Attributes, Resources And Filtering |
| 050 / 02 | The Transform Processor And Data Safety |

Each section ends with a capstone lab and `quiz.yaml`; `sections/final-domain-quiz.yaml` closes the course.

## Author Review

See [curriculum coverage](CURRICULUM.md), [primary sources](SOURCES.md) and [contribution instructions](CONTRIBUTING.md). No runtime execution is claimed. The files in `assessments/` are legacy reading-only question banks.
