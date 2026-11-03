# Curriculum Coverage

Exam: OpenTelemetry Certified Associate (OTCA). Domain: The OpenTelemetry Collector (26%).

The [official objectives](https://training.linuxfoundation.org/certification/opentelemetry-certified-associate-otca/) were checked on 2026-10-11. Teaching structure is independently authored and does not add official requirements.

| Section | Official objective | Modules | Status |
| --- | --- | --- | --- |
| 010 | Configuration | 2 + capstone | Built; labs untested |
| 020 | Deployment | 2 + capstone | Built; labs untested |
| 030 | Scaling | 2 + capstone | Built; labs untested |
| 040 | Pipelines | 2 + capstone | Built; labs untested |
| 050 | Transforming Data | 2 + capstone | Built; labs untested |

| Section / module | Module | Teaching lessons | Learning outcomes |
| --- | --- | --- | --- |
| 010 / 01 | Component Definitions And Enabled Pipelines | 3 | See `sections/section-010/README.md` |
| 010 / 02 | Configuration Sources, Environment Values And Extensions | 3 | See `sections/section-010/README.md` |
| 020 / 01 | Agent Deployment Patterns | 3 | See `sections/section-020/README.md` |
| 020 / 02 | Gateway Deployment And Agent-To-Gateway Export | 3 | See `sections/section-020/README.md` |
| 030 / 01 | Capacity Signals And Protecting The Collector | 3 | See `sections/section-030/README.md` |
| 030 / 02 | Sharding And Stateful Processing | 3 | See `sections/section-030/README.md` |
| 040 / 01 | Signal Paths, Shared Components And Fan-Out | 3 | See `sections/section-040/README.md` |
| 040 / 02 | Connectors, Backpressure And Failure Behavior | 3 | See `sections/section-040/README.md` |
| 050 / 01 | Attributes, Resources And Filtering | 3 | See `sections/section-050/README.md` |
| 050 / 02 | The Transform Processor And Data Safety | 3 | See `sections/section-050/README.md` |

Every section begins with an introduction. Every module has a playground, a graded lab and a summary. Each section ends with a capstone lab and `quiz.yaml`; `sections/final-domain-quiz.yaml` closes the course. Learning outcomes per module are in each section README and in `AUTHORING.yaml`.

The labs and playgrounds are built untested: static checks only, no runtime execution is claimed. Technical content remains draft until review.
