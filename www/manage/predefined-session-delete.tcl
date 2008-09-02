# packages/dotlrn-ecommerce/www/admin/predefined-session-delete.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-25
    @arch-tag: d8338236-fc0a-4804-8fc8-39648e9554e6
    @cvs-id $Id$
} {
    {session_id:integer,multiple {}}
    return_url
} -properties {
} -validate {
} -errors {
}

if { [llength $session_id] } {
    db_dml delete_sesions [subst {
	delete from dotlrn_ecommerce_predefined_sessions
	where session_id in ([join $session_id ,])
    }]
}

ad_returnredirect $return_url