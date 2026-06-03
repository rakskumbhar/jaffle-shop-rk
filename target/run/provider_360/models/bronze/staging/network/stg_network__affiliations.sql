
  create or replace   view SNOWFLAKE_LEARNING_DB.RAW.stg_network__affiliations
  
    
    
(
  
    "NETWORK_AFFILIATION_ID" COMMENT $$Unique identifier for the network affiliation record$$, 
  
    "NPI_NUMBER" COMMENT $$10-digit National Provider Identifier$$, 
  
    "NETWORK_NAME" COMMENT $$$$, 
  
    "NETWORK_TIER" COMMENT $$$$, 
  
    "PARTICIPATION_STATUS" COMMENT $$$$, 
  
    "EFFECTIVE_DATE" COMMENT $$Date network participation became effective$$, 
  
    "TERMINATION_DATE" COMMENT $$$$, 
  
    "PAR_AGREEMENT_TYPE" COMMENT $$$$, 
  
    "_SOURCE_LOADED_AT" COMMENT $$Timestamp when record was loaded into raw ingestion$$
  
)

   as (
    with source as (
    select * from SNOWFLAKE_LEARNING_DB.RAW_INGESTION.network_affiliations_raw
),

renamed as (
    select
        network_affiliation_id::varchar   as network_affiliation_id,
        npi_number::varchar(10)           as npi_number,
        network_name::varchar             as network_name,
        network_tier::varchar             as network_tier,
        participation_status::varchar     as participation_status,
        effective_date::date              as effective_date,
        termination_date::date            as termination_date,
        par_agreement_type::varchar       as par_agreement_type,
        _loaded_at::timestamp_ntz         as _source_loaded_at
    from source
)

select * from renamed
  );

