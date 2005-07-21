ad_page_contract {
    serve the correct template based from what is template assigned
    on the cms_context of public
} {
    file_id
}

if {![db_0or1row get_item "select cr.*,
      ci.*
      from cr_revisions cr,
      cr_items ci
      where ci.live_revision = cr.revision_id
      and ci.item_id=:file_id" -column_array current_item]} {
    
    set current_item(title) "Section Details placeholder"
    set current_item(content) "Empty"
    set current_item(name) ""
    set current_item(mime_type) "text/html"
} else {
if { ![string equal -length 4 "text" $current_item(mime_type)] } {
    # It's a file.
    cr_write_content -revision_id $current_item(revision_id)
    ad_script_abort
} else {
    set current_item(content) [cr_write_content -string -revision_id $current_item(revision_id)]
}

}


ad_return_template
    


