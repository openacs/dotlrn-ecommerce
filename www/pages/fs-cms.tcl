ad_page_contract {
    serve the correct template based from what is template assigned
    on the cms_context of public
} {
    file_id
}


#content::item::get -item_id $file_id -revision "live" -array_name current_item -resolve_index t
# we can't use content_item::get because table_name for
# file_storage_object is FS_ROOT_FOLDERS!!

db_1row get_item "select cr.*,
      ci.*
      from cr_revisions cr,
      cr_items ci
      where ci.live_revision = cr.revision_id
      and ci.item_id=:file_id" -column_array current_item

if { ![string equal -length 4 "text" $current_item(mime_type)] } {
    # It's a file.
    cr_write_content -revision_id $current_item(revision_id)
    ad_script_abort
}

set index_p f
if {[string equal "benefits" $current_item(name)] || ([string equal "index" $current_item(name)] && ![string equal "" [ad_conn path_info]])} {
    set index_p t
    set root_id $current_item(parent_id)
    # get the folders under this and use them as sections
    db_multirow -extend {pdf_p} sections get_child_folders {
	select parent_id as folder_id,
	       content_folder__get_label(parent_id) as folder_label,
	       item_id,
	       content_item__get_title(item_id) as item_label,
	       content_item__get_path(item_id, :root_id) as item_path,
	       tree_sortkey
	from cr_items
	where parent_id in (select folder_id 
			    from cr_folders, cr_items i2
			    where folder_id = i2.item_id and i2.parent_id = :root_id)
	      and live_revision is not null
	union
	select parent_id as folder_id,
	       content_folder__get_label(parent_id) as folder_label,
	       item_id,
	       content_extlink__get_label(item_id) as item_label,
	       content_extlink__get_url(item_id) as item_path,
               tree_sortkey
	from cr_items
	where parent_id in (select folder_id 
			    from cr_folders, cr_items i2
			    where folder_id = i2.item_id and i2.parent_id = :root_id)
	      and content_type = 'content_extlink'
	order by tree_sortkey
    } {
	set pdf_p [regexp -- {.+\.pdf$} $item_path]
    }
}
#ad_return_complaint 1 "**'[ad_conn path_info]'**"
if {[string equal "index" $current_item(name)] || [string equal "benefits" [string trim [ad_conn path_info]]]} {
    set blackbackground_p 1
} else {
    set blackbackground_p 0
}
ad_return_template
    


