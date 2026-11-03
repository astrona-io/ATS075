---
draft: true
exam_objectives:
  - Transforming Data
---
# Summary

The Collector changes telemetry between the receiver and the exporter. Three processors do the simple jobs. The attributes processor changes the attributes of spans, log records and metric data points. The resource processor changes the attributes of the resource, which describes the producer. The filter processor drops whole items when a condition is true. Each of them changes the evidence that later steps and later readers receive.

## What you learned

The attributes processor and the resource processor use the same actions. `insert` adds a key only when it is missing, `update` replaces a value only when the key exists, and `upsert` does both. `delete` removes a key and `hash` replaces a value with a fixed-length hash that hides the value but still lets you count equal values. The actions run in the order of the list. A processor only works when its name is in the `processors` list of a pipeline, and the Collector reads its configuration only at start, so a changed ConfigMap needs a restart.

The filter processor uses conditions in the OpenTelemetry Transformation Language. Each signal has its own list of conditions, and a true condition drops the item. The conditions in one list are combined with OR. The `error_mode` setting decides what happens when a condition fails: `ignore` logs the error and goes on, `silent` goes on without a log line, and `propagate` drops the whole payload. Every choice trades lost data against unchecked data.

The order of the `processors` list is the order of execution, and each processor sees the output of the one before it. A filter that reads an attribute stops matching when an earlier processor deletes or rewrites that attribute, and the pipeline still starts without an error. The level of an attribute matters as well. Resource attributes and span attributes are different data even when their keys are the same, and each processor reaches only its own level.

The key facts to remember are these:

- A true filter condition drops the item.
- The `processors` list defines both use and order.
- The attributes processor never changes resource attributes, and the resource processor never changes span attributes.
- Deleting or filtering data cannot be undone for every exporter that comes later in the pipeline.
- A filter selects a part of the traffic, so readers must know that they see only that part.

<!-- astrona:playground:destroy -->
