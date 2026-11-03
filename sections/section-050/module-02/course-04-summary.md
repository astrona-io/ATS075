---
draft: true
exam_objectives:
  - Transforming Data
---
# Summary

The transform processor runs statements in the OpenTelemetry Transformation Language against spans, log records and metric data points. It can change a part of a value, choose with a condition and rewrite several levels. That power makes it the main tool for redaction, and also a source of mistakes, because every statement changes the evidence that later readers see.

## What you learned

A statement has a function, a path and an optional `where` clause. The first word of a path names the context: `span`, `log`, `datapoint` or a level above them such as `resource`. Each signal has its own list of statements (`trace_statements`, `metric_statements` and `log_statements`), and a path from another signal is not allowed. Statements run in the order of the list, and later statements see the changes of earlier ones.

Redaction uses `delete_key` and `delete_matching_keys` to remove attributes, `replace_pattern` to mask a part of a value, and `SHA256` to replace a value with a hash. A statement that reads a missing attribute fails. Under `error_mode: ignore`, the failure is logged and the change is skipped, so a protection can quietly not run. Under `propagate`, the failure drops the whole payload. A `where` clause that checks for the attribute avoids both outcomes. Redaction is a second line of defense, because it covers only the values that someone thought of, and avoiding the secret at the source is safer.

A metric data point is identified by the metric name, the resource, the scope and its attributes. Deleting or renaming an attribute can make two data points share one identity, and the processor does not merge them or sum their values. Removing an identifier lowers cardinality, but the correct sum needs a separate aggregation. Renaming a metric or a key breaks every dashboard and alert that uses the old name.

The layout of the pipelines decides who sees the original data. A receiver can feed several pipelines, and a processor protects only the pipelines where it is listed. A diagnostic exporter in a pipeline without the processor receives everything. The debug exporter shows the result of a transformation at its position and is the right tool to verify a change with test data, but it prints sensitive values to the log and does not prove that all cases are covered.

The key facts to remember are these:

- Guard each statement with `where` so that it runs only on items that have the attribute.
- Redaction does not replace removing the secret at the source.
- Deleting a metric attribute changes identity and does not aggregate.
- Put the redaction in every pipeline that must not show the original.
- Verify with test data, and treat the debug exporter as a place where secrets can leak.

<!-- astrona:playground:destroy -->
