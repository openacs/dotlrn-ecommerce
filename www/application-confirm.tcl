ad_page_contract {
} {
    {product_id:notnull}
}

set section_name [db_string get_name {
    select c.course_name||': '||s.section_name
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items i
    where product_id = :product_id
          and c.item_id = s.course_id
          and i.live_revision = c.revision_id
} -default ""]