ad_page_contract {
    We want to see the assessment session even though we don't have admin
    over the assessment package.
    If we have admin over the community, we can see the application
    assessment session.
    session_id:integer,notnull
} {

}

# get mapping to make sure this is an applicaiton for dotlrn-ecommerce
# section
set form [ns_getform]
set session_id [ns_set iget $form session_id]
set community_id [db_string get_community_id "select r.object_id_one from acs_rels r, dotlrn_ecommerce_application_assessment_map m where m.rel_id = r.rel_id and m.session_id = :session_id" -default ""]
if {$community_id eq ""} {
    ad_return_complaint 1 "Invalid session"
    ad_script_abort
}

permission::require_permission \
    -object_id $community_id \
    -party_id [ad_conn user_id] \
    -privilege "admin"

# once we know we have permission just include the session results page
# from assessment.

set page_title "Application"
set context [list $page_title]
