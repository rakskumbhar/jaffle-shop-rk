{% snapshot snp_provider_attributes %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='npi_number',
        strategy='check',
        check_cols=[
            'npi_status',
            'specialty_code',
            'primary_taxonomy_code',
            'board_certification',
            'credential_status',
            'facility_name',
            'address_line_1',
            'city',
            'state_code',
            'zip_code',
            'is_accepting_patients',
            'provider_status',
            'deactivation_date',
            'reactivation_date'
        ],
        invalidate_hard_deletes=true
    )
}}

select * from {{ ref('int_providers__unified') }}

{% endsnapshot %}
