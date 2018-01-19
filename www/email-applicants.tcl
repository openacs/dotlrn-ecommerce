# packages/dotlrn-ecommerce/www/email-applicants.tcl

ad_page_contract {
    
    sends out email to applicants
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-16
    @arch-tag: aa9fd47b-ab34-4d20-80dc-6c91076e1d37
    @cvs-id $Id$
} {
    {rel_id:integer,multiple ""}
    {return_url "applications"}
} -properties {
} -validate {
} -errors {
}

if {[empty_string_p $rel_id]} {
    ad_returnredirect $return_url
    ad_script_abort
}

permission::require_permission -object_id [ad_conn package_id] -privilege admin

set title "[_ dotlrn-ecommerce.Email_applicants]"
set context [list [list "applications" "[_ dotlrn-ecommerce.lt_Waiting_List_and_Prer]"] $title]
set header_stuff {}
set focus {}

ad_form \
    -name spam \
    -export { return_url } \
    -form {
        {from:text(inform) {label "[_ bulk-mail.From]"}}
	{recipients:text(inform) {label "[_ dotlrn-ecommerce.Recipients]"}}
        {subject:text(text) {label "[_ bulk-mail.Subject]"} {html {size 60}}}
        {message:richtext(richtext) {label "[_ bulk-mail.Message]"} {html {rows 20 cols 80 wrap soft}} {nospell 1}}
        {send_date:date {label "[_ bulk-mail.Send_Date]"} {format {MONTH DD YYYY HH12 MI AM}}}
        {query:text(hidden)}
    } \
    -on_request {
        set from [acs_user::get_element -user_id [ad_conn user_id] -element email]
        set send_date [template::util::date::now_min_interval]
	set user_id_list [db_list get_user_ids "select distinct object_id_two from acs_rels where rel_id in ([join $rel_id ,])"]
	set query "select pa.email, pe.first_names, pe.last_name from parties pa, persons pe where pa.party_id = pe.person_id and pa.party_id in ([join $user_id_list ,])"
	db_foreach get_recipients $query {
	    append recipients "$first_names $last_name ($email)<br />"
	}
	set message [template::util::richtext::create {} "text/enhanced"]
    } \
    -on_submit {
	set body [template::util::richtext::get_property content $message]
	set format [template::util::richtext::get_property format $message]
	ns_log Notice "DEDSMAN: $body : $format"
	bulk_mail::new \
	    -package_id [ad_conn package_id] \
	    -send_date [template::util::date::get_property linear_date $send_date] \
	    -date_format "YYYY MM DD HH24 MI SS" \
	    -from_addr $from \
	    -subject "$subject" \
	    -message $body \
	    -message_type html \
	    -query $query
    } \
    -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }
