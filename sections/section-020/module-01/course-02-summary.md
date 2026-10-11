---
draft: true
exam_objectives:
- Deployment
---
# Summary

Agent collection places telemetry handling near workloads, while gateway collection centralizes selected processing and export. Combining them can separate local enrichment from shared policy, but each tier creates capacity and availability responsibilities. Producer identity must survive the path, credentials must fit the boundary, and buffers remain bounded. Deployment topology should follow signal and failure requirements rather than assume that another tier automatically provides durability or privacy.
