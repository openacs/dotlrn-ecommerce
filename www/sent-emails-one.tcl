# packages/dotlrn-ecommerce/www/sent-emails-one.tcl

ad_page_contract {
    
    view one detail
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-16
    @arch-tag: aa9fd47b-ab34-4d20-80dc-6c91076e1d37
    @cvs-id $Id$
} {
    {bulk_mail_id:notnull,integer}
} -properties {
} -validate {
} -errors {
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege admin

db_1row select_message_info {
    select bulk_mail_messages.bulk_mail_id,
           to_char(bulk_mail_messages.send_date, 'Mon DD YYYY HH24:MI') as send_date,
           bulk_mail_messages.status,
           bulk_mail_messages.from_addr,
           bulk_mail_messages.subject,
           bulk_mail_messages.reply_to,
           bulk_mail_messages.extra_headers,
           bulk_mail_messages.message,
           bulk_mail_messages.query
    from bulk_mail_messages
    where bulk_mail_messages.bulk_mail_id = :bulk_mail_id
}

set subject [ad_quotehtml $subject]
set message [ad_quotehtml $message]

set title $subject
set context [list [list "applications" "[_ dotlrn-ecommerce.lt_Waiting_List_and_Prer]"] [list "sent-emails" "[_ dotlrn-ecommerce.View_previously_email]"] $title]
set header_stuff {}
set focus {}


set recipients ""
db_foreach get_recipients $query {
    append recipients "$first_names $last_name ($email)<br />"
}