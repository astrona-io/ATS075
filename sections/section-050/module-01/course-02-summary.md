---
draft: true
exam_objectives:
- Transforming Data
---
# Summary

Collector transformations can enrich, normalize, redact or filter telemetry under supported component contracts. They change the evidence available to consumers, so scope and ordering matter. Removing an attribute can alter metric identity, while filtering can erase the observations needed to investigate an incident. Error behavior must be deliberate. Redaction should precede prohibited disclosure and should be complemented by source-side minimization rather than treated as automatic privacy.
