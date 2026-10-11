---
draft: true
exam_objectives:
- Scaling
---
# Summary

Collector scaling depends on the component that limits useful throughput. Stateless forwarding, active scraping and stateful processing have different distribution needs. Scrapers need target ownership, while tail sampling needs related spans to converge at an appropriate instance. Persistent destination failure is not repaired by adding producers of export traffic. Queue, failure and resource evidence should guide a bounded scaling decision.
