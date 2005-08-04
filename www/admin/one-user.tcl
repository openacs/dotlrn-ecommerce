# /pvt/home.tcl

ad_page_contract {
    user's workspace page
    @cvs-id $Id$
} {
    user_id:integer,notnull
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

acs_user::get -array user -include_bio -user_id $user_id

set account_status [ad_conn account_status]
set login_url [ad_get_login_url]
set subsite_url [ad_conn vhost_subsite_url]

set page_title "[_ dotlrn-ecommerce.User_information_for] [person::name -person_id $user_id]"

set pvt_home_url [ad_pvt_home]

set context [list $page_title]

set ad_url [ad_url]

set return_url [ad_return_url]

db_multirow -extend { order_url } orders get_orders {
    select o.order_id, confirmed_date
    from ec_orders o, dotlrn_ecommerce_transactions t, ec_items i, dotlrn_ecommerce_section s
    where o.order_id = t.order_id
    and o.order_id = i.order_id
    and i.product_id = s.product_id
    and user_id=:user_id
    and order_state not in ('in_basket','void','expired')
    group by o.order_id, confirmed_date
    order by o.order_id
} {
    set order_url [export_vars -base ecommerce/one { order_id }]
    set confirmed_date [util_AnsiDatetoPrettyDate $confirmed_date]
}

set sessions_with_applications 0
db_multirow -extend { asm_url edit_asm_url } sessions sessions {
    select c.community_id, c.pretty_name
    from dotlrn_member_rels_full r, dotlrn_communities c
    where r.community_id = c.community_id
    and r.member_state = 'awaiting payment'
    and r.user_id = :user_id
} {
    if { [db_0or1row assessment {
	select ss.session_id, c.assessment_id
	
	from dotlrn_ecommerce_section s,
	(select c.*
	 from dotlrn_catalogi c,
	 cr_items i
	 where c.course_id = i.live_revision) c,
	(select a.*
	 from as_assessmentsi a,
	 cr_items i
	 where a.assessment_id = i.latest_revision) a,
	as_sessions ss
	
	where s.community_id = :community_id
	and s.course_id = c.item_id
	and c.assessment_id = a.item_id
	and a.assessment_id = ss.assessment_id
	and ss.subject_id = :user_id
	
	order by creation_datetime desc
	
	limit 1
    }] } {
	set asm_url [export_vars -base /assessment/session { session_id }]
	set edit_asm_url [export_vars -base /assessment/assessment { assessment_id }]
	incr sessions_with_applications
    }
}

set catalog_url [ad_conn package_url]