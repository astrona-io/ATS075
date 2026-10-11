---
draft: true
exam_objectives:
- Transforming Data
---
# Attribute Changes, Filtering And Transformation Safety

Collector transformations change telemetry after collection and before selected delivery. Supported processors can enrich attributes, normalize values, redact fields or remove records. Some use specialized configuration, while broader transformation components can use an expression language such as OTTL. The selected distribution and component version determine what operations and contexts are available.

A transformation is evidence processing, not merely formatting. Changing a service identity can alter which application appears responsible. Removing a trace attribute can reduce investigative detail. Filtering a class of logs can remove the only explanation for a failure. Authors should state what information changes and why that change is appropriate for the intended consumers.

Scope is essential. Resource attributes apply to the producing entity, while span, metric and log attributes describe particular observations. A rule intended to normalize one operation field should not accidentally rewrite the entire resource identity. An expression valid in one context may not refer to the same data in another. The processing contract needs the correct signal and attribute location.

Consider redacting a token accidentally attached to spans. The safe design first avoids collecting it at the source. A downstream redaction can provide additional protection before approved export. If a diagnostic exporter receives the original spans before redaction, confidential data has already crossed a boundary. The position of the rule therefore matters as much as its presence in configuration.

Ordering also affects filters. A filter can match a raw value before normalization or a normalized value afterward. Those populations need not be identical. If an author changes the order without reviewing meaning, dashboards may suddenly lose a class of observations even though the pipeline remains syntactically valid. Review should use representative cases and the declared expression semantics, without inventing runtime results.

Metric transformations need special care because attributes participate in stream identity. Removing a distinguishing attribute can make formerly separate streams share an identity. Renaming units or instrument names without corresponding value semantics can mislead consumers. Combining data safely can require a supported aggregation operation rather than simply deleting labels and assuming the result is mathematically correct.

Error modes determine how malformed expressions or unexpected data affect processing. A component may propagate an error, ignore an error or use another documented behavior. That choice can affect data loss and observability of failures. Silently ignoring every error may preserve traffic while concealing that the privacy or normalization rule did not run. Failing all data can protect a boundary at the cost of evidence availability. The choice belongs to the actual policy and component contract.

Filtering can reduce cost and noise, but it changes the visible population. Removing all successful spans may help an error-focused investigation while making latency analysis unrepresentative. Excluding repetitive logs can hide changes in frequency. Downstream users need to know that the retained data is a selected population rather than a complete record of activity.

Version and schema compatibility should accompany rules. An instrumentation upgrade can rename an attribute that a transformation expects. The rule can then stop matching without any application outage. A maintained mapping between producer conventions, transformation inputs and consumer queries helps locate that failure. Broad expressions that guess every possible field name can create their own ambiguous behavior.

The useful reasoning identifies input scope, intended change, affected population, failure behavior and disclosure boundary. This makes transformation review concrete and allows students to explain why a rule belongs at a particular point in the pipeline.

## Common pitfalls

> [!WARNING]
> Transformations can change identity, population and investigative meaning. Do not delete metric dimensions and assume safe aggregation. Review expression context and errors, and place privacy controls before every destination that must not receive the original data.
