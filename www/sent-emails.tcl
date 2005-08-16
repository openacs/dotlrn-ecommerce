# packages/dotlrn-ecommerce/www/sent-emails.tcl

ad_page_contract {
    
    view emails sent to applicants
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-16
    @arch-tag: aa9fd47b-ab34-4d20-80dc-6c91076e1d37
    @cvs-id $Id$
} {
} -properties {
} -validate {
} -errors {
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege admin

set title "[_ dotlrn-ecommerce.View_previously_email]"
set context [list [list "applications" "[_ dotlrn-ecommerce.lt_Waiting_List_and_Prer]"] $title]
set header_stuff {}
set focus {}

template::list::create \
    -name bulk_mails \
    -multirow bulk_mails \
    -elements {
	send_date_pretty {
	    label "[_ bulk-mail.Send_Date]"
	}
	from_addr {
	    label "[_ bulk-mail.From]"
	}
	subject {
	    label "[_ bulk-mail.Subject]"
	    link_url_col details_url
	}
	status_pretty {
	    label "[_ bulk-mail.Status]"
	}
    }

db_multirow -extend {status_pretty send_date_pretty details_url} bulk_mails bulk_mails {
    select m.*
    from bulk_mail_messages m
    where m.package_id = :package_id
    order by send_date desc
} {
    set send_date_pretty [lc_time_fmt $send_date "%q"]
    set status_pretty [ad_decode $status sent [_ bulk-mail.Sent] pending [_ bulk-mail.Pending] [_ bulk-mail.Cancelled]]
    set details_url [export_vars -base "sent-emails-one" {bulk_mail_id}]
}
