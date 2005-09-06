# packages/dotlrn-ecommerce/www/ecommerce/application-request-2.tcl

ad_page_contract {
    
    Try to set the assessment subject to the purchaser
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-24
    @arch-tag: 1a9bde71-7fff-41f1-a351-c8578bb46173
    @cvs-id $Id$
} {
    user_id:integer,notnull
    return_url:notnull
    rel_id:integer,notnull
    session_id:integer,notnull,optional
} -properties {
} -validate {
} -errors {
}

set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]
set viewing_user_id [ad_conn user_id]

if { ! [exists_and_not_null session_id] && ! [empty_string_p $assessment_id] } {
    set session_id [db_string session {
	select ss.session_id
	
	from (select a.*
	      from as_assessmentsi a,
	      cr_items i
	      where a.assessment_id = i.latest_revision) a,
	as_sessions ss
	
	where a.assessment_id = ss.assessment_id
	and a.item_id = :assessment_id
	and ss.subject_id = :viewing_user_id
	
	order by creation_datetime desc
	
	limit 1
    }]

    db_dml set_assessment_subject {	
	update as_sessions	
	set subject_id = :user_id
	where session_id = :session_id
    }
}

# Create a mapping for the application rel_id and the assessment
# session
if { [exists_and_not_null session_id] } {
    db_dml map_application_to_assessment {
	insert into dotlrn_ecommerce_application_assessment_map
	values (:rel_id, :session_id)
    }
}

ad_returnredirect $return_url