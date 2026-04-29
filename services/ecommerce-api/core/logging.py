import structlog
from opentelemetry import trace

def add_opentelemetry_context(logger, method_name, event_dict):
    """
    Add OpenTelemetry context to the log record.
    """
    span = trace.get_current_span()
    if span.is_recording():
        span_context = span.get_span_context()
        event_dict["trace_id"] = format(span_context.trace_id, "032x")
        event_dict["span_id"] = format(span_context.span_id, "016x")
    return event_dict
