{% macro get_audit_relation() %}
    {%- set audit_table = 
        api.Relation.create(
            identifier='dbt_audit_log', 
            schema=target.schema~'_meta', 
            type='table'
        ) -%}
    {{ return(audit_table) }}
{% endmacro %}


{% macro get_audit_schema() %}
    {% set audit_table = get_audit_relation() %}
    {{ return(audit_table.quoted(audit_table.schema)) }}    
{% endmacro %}


{% macro log_audit_event(event_name) %}

    insert into {{ get_audit_relation() }} (
        event_name, 
        event_timestamp, 
        event_schema, 
        event_model,
        invocation_id
        ) 
    
    values (
        '{{ event_name }}', 
        {{dbt_utils.current_timestamp()}}::{{dbt_utils.type_timestamp()}}, 
        '{{ this.schema }}', 
        '{{ this.name }}',
        '{{ invocation_id }}'
        )

{% endmacro %}


{% macro create_audit_schema() %}
    create schema if not exists {{ get_audit_schema() }}
{% endmacro %}


{% macro create_audit_log_table() %}

    create table if not exists {{ get_audit_relation() }}
    (
       event_name       varchar(512),
       event_timestamp  {{dbt_utils.type_timestamp()}},
       event_schema     varchar(512),
       event_model      varchar(512),
       invocation_id    varchar(512)
    )

{% endmacro %}


{% macro log_run_start_event() %}
    {{log_audit_event('run started')}}
{% endmacro %}


{% macro log_run_end_event() %}
    {{log_audit_event('run completed')}}; commit;
{% endmacro %}


{% macro log_model_start_event() %}
    {{log_audit_event('model deployment started')}}
{% endmacro %}


{% macro log_model_end_event() %}
    {{log_audit_event('model deployment completed')}}
{% endmacro %}