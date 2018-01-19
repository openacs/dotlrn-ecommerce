ad_page_contract {

    Delete a section

    @author Hamilton Chua
    @creation-date 2004-05-01
    @version $Id$
} {
    section_id:notnull
    {return_url "" }
}

set page_title "Delete Section"
set context $page_title

set attendees [dotlrn_ecommerce::section::attendees $section_id]

# Don't allow deletion of sections with attendees
if { $attendees <= 0 } {
    # create confirmation form
    set content "Are you sure you want to remove this section ? "

    ad_form -name delete_section  \
	-cancel_url $return_url  \
	-form {
	    {return_url:text(hidden) { value $return_url } }
	    {section_id:text(hidden)  { value $section_id } }
	} -on_submit {

	    # HAM : 
	    # for now just delete from dotlrn_ecommerce_sections and then archive
	    # discuss what else needs to be done for delete
	    
	    set community_id [db_string "getcomid" "select community_id from dotlrn_ecommerce_section where section_id=:section_id"]
	    
	    # delete from section table
	    db_dml "delete section"  "delete from dotlrn_ecommerce_section where section_id=:section_id "
	    
	    # archive community
	    dotlrn_community::archive -community_id $community_id



	} -after_submit {
	    ad_returnredirect $return_url
	    ad_script_abort
	}
} else {
    set content "This section currently has participants and cannot be removed."
}
