---
draft: true
exam_objectives:
- Pipelines
---
# Summary

A Collector pipeline is an enabled signal path from receivers through ordered processors to exporters. Shared components and fan-out connect paths without making their consequences independent. Processing order can change data, while destination pressure can affect delivery behavior according to component contracts. A valid path must preserve the signal model and provide observable failures. More exporters increase destinations and responsibility rather than guaranteeing a more complete record.
