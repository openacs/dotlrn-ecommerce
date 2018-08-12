# /pvt/home.tcl

ad_page_contract {
    user's workspace page
    @cvs-id $Id$
} {
    {cancel ""}
} -properties {
    system_name:onevalue
    context:onevalue
    full_name:onevalue
    email:onevalue
    url:onevalue
    screen_name:onevalue
    bio:onevalue
    portrait_state:onevalue
    portrait_publish_date:onevalue
    portrait_title:onevalue
    export_user_id:onevalue
    ad_url:onevalue
    member_link:onevalue
    pvt_home_url:onevalue
}

set memoize_max_age [parameter::get -parameter CatalogMemoizeAge -default 10800]
set user_id [auth::require_login -account_status closed]

acs_user::get -array user -user_id $user_id

set account_status [ad_conn account_status]
set login_url [ad_get_login_url]
set subsite_url [ad_conn vhost_subsite_url]

set page_title [ad_pvt_home_name]

set pvt_home_url [ad_pvt_home]

set context [list $page_title]

set fragments [callback -catch user::workspace -user_id $user_id]

set ad_url [ad_url]

set community_member_url [acs_community_member_url -user_id $user_id]

set notifications_url [lindex [site_node::get_children -node_id [subsite::get_element -element node_id] -package_key "notifications"] 0]

set system_name [ad_system_name]

set return_url [ad_return_url]

set portrait_upload_url [export_vars -base "../user/portrait/upload" { return_url }]

if { [llength [lang::system::get_locales]] > 1 } { 
    set change_locale_url [apm_package_url_from_key "acs-lang"]
}



if [ad_parameter SolicitPortraitP "user-info" 0] {
    # we have portraits for some users 
    if ![db_0or1row get_portrait_info "
    select cr.publish_date, nvl(cr.title,'your portrait') as portrait_title
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    "] {
	set portrait_state "upload"
    } else {
        if { [empty_string_p $portrait_title] } {
            set portrait_title "[_ acs-subsite.no_portrait_title_message]"
        }

	set portrait_state "show"
	set portrait_publish_date [lc_time_fmt $publish_date "%q"]
    }
} else {
    set portrait_state "none"
}


set whos_online_url "[subsite::get_element -element url]shared/whos-online"
set make_visible_url "[subsite::get_element -element url]shared/make-visible"
set make_invisible_url "[subsite::get_element -element url]shared/make-invisible"
set invisible_p [whos_online::user_invisible_p [ad_conn untrusted_user_id]]

db_multirow -extend { order_url } orders get_orders {
    select o.order_id, confirmed_date
    from ec_orders o, dotlrn_ecommerce_transactions t, ec_items i, 
    dotlrn_ecommerce_section s
    where o.order_id = t.order_id
    and o.order_id = i.order_id
    and i.product_id = s.product_id
    and user_id=:user_id
    and order_state not in ('in_basket','void','expired')
    group by o.order_id, confirmed_date
    order by o.order_id
} {
    set order_url [export_vars -base order { user_id order_id }]
    set confirmed_date [util_AnsiDatetoPrettyDate $confirmed_date]
}

set applications_p [parameter::get -parameter EnableCourseApplicationsP -default 0]
set use_embedded_application_view_p [parameter::get -parameter UseEmbeddedApplicationViewP -default 0]


set sessions_with_applications 0
# check for patron rels as well

set default_assessment_id [parameter::get -parameter ApplicationAssessment -default ""]

    db_multirow -extend { asm_url edit_asm_url register_url cancel_url } sessions sessions {
	select c.community_id, c.pretty_name,r.user_id as participant_id,
	acs_object__name(r.user_id) as name, r.member_state, 
	r.rel_id, s.product_id, m.session_id

	from 
	dotlrn_communities c, dotlrn_ecommerce_section s,
	dotlrn_member_rels_full r
	left join dotlrn_ecommerce_application_assessment_map m
	on (r.rel_id = m.rel_id),
	acs_objects o

	where r.community_id = c.community_id
	and s.community_id = c.community_id
	and o.object_id = r.rel_id
	and r.member_state in ('request approval', 'request approved', 'application sent', 'application approved')
	and (r.user_id = :user_id or o.creation_user=:user_id)
    } {
	append notice "community_id '${community_id}' participant = '${participant_id}' <br />"

	set assessment_id [db_string get_assessment_id {
	    select a.item_id
	    from as_sessions s, as_assessmentsi a
	    where s.assessment_id = a.assessment_id
	    and session_id = :session_id
	}]

	if {$use_embedded_application_view_p == 1} {
	    set asm_url "admin/application-view?session_id=$session_id"
	    
	} else {
	    
	    set asm_url [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]asm-admin/results-session" { session_id }]
	    
	}

	set edit_asm_url [export_vars -base /assessment/assessment { session_id assessment_id }]
	set cancel_url [export_vars -base application-reject { community_id user_id {send_email_p 0} return_url }]
	   
	set register_url [export_vars -base ecommerce/shopping-cart-add { user_id product_id participant_id}]
	incr sessions_with_applications
    }

# get waiting list requests
db_multirow -extend {waiting_list_number register_url} waiting_lists waiting_lists {
	select c.community_id, c.pretty_name,r.user_id as participant_id,
	acs_object__name(r.user_id) as name, r.member_state,
        s.product_id
	from 
	dotlrn_communities c, dotlrn_ecommerce_section s,
	dotlrn_member_rels_full r,
        acs_objects o
        where o.object_id = r.rel_id
        and s.community_id = c.community_id
	and r.community_id = c.community_id
	and r.member_state in ('needs approval', 'waitinglist approved')
	and (r.user_id = :user_id or o.creation_user=:user_id)
    } {
	set waiting_list_number [util_memoize [list dotlrn_ecommerce::section::waiting_list_number $participant_id $community_id] $memoize_max_age]
	
	set register_url [export_vars -base ecommerce/shopping-cart-add { user_id product_id participant_id}]
    }

#ad_return_complaint 1 $notice
set catalog_url [ad_conn package_url]
set cc_package_id [apm_package_id_from_key "dotlrn-ecommerce"]
set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]

set reg_asm_id [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id] -default ""]
if { ! [empty_string_p $reg_asm_id] } {
    if { [db_0or1row get_reg_session {
	select assessment_id, session_id
	from as_sessions
	where assessment_id in (select assessment_id
				from as_assessmentsi
				where item_id = :reg_asm_id)
	and subject_id = :user_id
	and not completed_datetime is null
	limit 1
    }] } {
	set edit_reg_url [export_vars -base [apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]assessment { {assessment_id $reg_asm_id} session_id }]
    }
}
