ad_page_contract {
    Toggle display_section_p
} {
    section_id:integer,notnull
    {return_url ".."}
}
    
db_dml toggle_display ""
    
ad_returnredirect $return_url
