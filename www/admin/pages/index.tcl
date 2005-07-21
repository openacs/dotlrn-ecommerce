ad_page_contract {
    Publically viewable pages
    stored in file-storage that belongs to a section
} -query {

} -properties {
    page_title
    context
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

set urlv [split [ad_conn path_info] "/"]
set section_id [lindex $urlv 0]
set the_url [lrange $urlv 1 end]

# TODO DAVEB Make this a procedure
set section_package_id [db_string get_package_id "select package_id from dotlrn_communities_all dc, dotlrn_ecommerce_section ds where ds.community_id=dc.community_id and ds.section_id=:section_id" -default 0]
if {$section_package_id == 0} {
#    ad_returnnotfound
#    ad_script_abort
	ad_return_complaint 1 "section_id '${section_id}' urlv '${urlv}' section_package_id '${section_package_id}'"
}

set section_community_node_id [site_node::get_node_id_from_object_id -object_id $section_package_id]
set fs_package_id [site_node::get_children -node_id $section_community_node_id -package_key file-storage -element package_id]
set fs_root_folder [fs::get_root_folder -package_id $fs_package_id]
set pages_folder [content::item::get_id -root_folder_id $fs_root_folder -item_path "public"]

#ad_return_complaint 1 "pages_folder '${pages_folder}'"

set page_title "Section Pages"
set context [list $page_title]

set return_url [ad_return_url]
ad_return_template