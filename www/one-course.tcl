ad_page_contract {
    show one course
    for now redirect to index page

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-06-02
} {
    course_id:integer,optional
    section_id:integer,optional
    cal_item_id:integer,optional
}

set user_id [ad_conn user_id]
set admin_p [permission::permission_p \
		 -object_id [ad_conn package_id] \
		 -party_id $user_id \
		 -privilege admin]
if {[info exists cal_item_id] && ![string equal "" $cal_item_id]} {
set course_id [db_string get_course_id "select ci.item_id from dotlrn_catalog d1,cr_items ci, (select distinct des.course_id from cal_items c,dotlrn_ecommerce_section des, dotlrn_communities dc, portal_element_map pem, portal_pages pp, portal_element_parameters pep where pep.key='calendar_id' and pep.value=c.on_which_calendar and pem.element_id=pep.element_id and pem.page_id=pp.page_id and pp.portal_id=dc.portal_id and c.cal_item_id=:cal_item_id and dc.community_id=des.community_id) d2 where d1.course_id=ci.live_revision and ci.item_id=d2.course_id" -default ""]

}
set course_return_url [ad_conn url]

# get categories mapped to course
set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
set category_trees [category_tree::get_mapped_trees $cc_package_id]
template::multirow create categories tree_name category_names
foreach category_tree $category_trees {
    set category_names [join [category::get_names [category::get_mapped_categories -tree_id [lindex $category_tree 0] [content::item::get_latest_revision -item_id $course_id]]] ", "]
    template::multirow append categories [lindex $category_tree 1] $category_names
}

set allow_free_registration_p [parameter::get -parameter AllowFreeRegistration -default 0]
set allow_other_registration_p [parameter::get -parameter AllowRegistrationForOtherUsers -default 1]

set memoize_max_age [parameter::get -parameter CatalogMemoizeAge -default 120]

set patron_communities [db_list patron_communities {
    select r.community_id from 
    dotlrn_member_rels_full r,
    acs_objects o
    where o.object_id = r.rel_id
    and r.member_state in ('request approval', 'request approved', 'needs approval', 'waitinglist approved')
    and o.creation_user=:user_id
    and r.user_id <> o.creation_user
}]
set offer_code_p [parameter::get -parameter OfferCodesP -default 0]
if { $offer_code_p } {
    set discount_clause [db_map discount]
} else {
    set discount_clause ""
}


db_multirow -extend {toggle_display_url patron_message member_state fs_chunk section_folder_id section_pages_url category_name community_url section_add_url section_edit_url course_grades section_grades section_zones sections_url member_p sessions instructor_names price prices shopping_cart_add_url attendees available_slots pending_p waiting_p approved_p instructor_p registration_approved_url button waiting_list_number asm_url cancel_url} sections get_sections {
		select dc.course_id, trim(dc.course_key) as course_key, dc.course_name,
			dc.assessment_id, dec.section_id, dec.section_name,
			dec.product_id, dec.community_id, dc.course_info,
			ci.item_id, v.maxparticipants, dec.show_participants_p, dec.show_sessions_p, dec.description, v.show_description_p, v.display_section_p, dec.show_price_p

		from dotlrn_catalog dc,
		cr_items ci
		left join dotlrn_ecommerce_section dec
		on (ci.item_id = dec.course_id)
		left join ec_custom_product_field_values v
		on (dec.product_id = v.product_id)
			
		where dc.course_id = ci.live_revision
                and ci.item_id = :course_id
                and (v.display_section_p is null or v.display_section_p = 't' or :admin_p = 1)
	
		order by lower(dc.course_name), lower(dec.section_name)
} {
    set course_name $course_name
    set course_rev_id $course_id
    set course_item_id $item_id

    # HAM : check NoPayment parameter
    # if we're not asking for payment, change shopping cart url
    # to dotlrn-ecommerce/register
    if { [parameter::get -package_id [ad_conn package_id] -parameter NoPayment -default 0] } {
	set shopping_cart_add_url [export_vars -base register/ { community_id product_id }]
    } else {
	if { $allow_other_registration_p } {
	    set shopping_cart_add_url [export_vars -base [ad_conn package_url]ecommerce/participant-change { user_id product_id return_url }]
	} else {
	    set return_url [export_vars -base [ad_conn package_url]ecommerce/shopping-cart-add { user_id product_id }]
	    if { $user_id == 0 } {
		set shopping_cart_add_url [export_vars -base [ad_conn package_url]ecommerce/login { return_url }]
	    } else {
		set shopping_cart_add_url $return_url
	    }
	}
    }

    set registration_approved_url [export_vars -base ecommerce/shopping-cart-add { user_id product_id}]

    set prices ""
    if { ! [empty_string_p $product_id] } {
	set prices [ec_pretty_price [set price [util_memoize [list dotlrn_ecommerce::section::price $section_id] $memoize_max_age]]]
	if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] } {
	    set member_price [util_memoize [list dotlrn_ecommerce::section::member_price $section_id] $memoize_max_age]
	    if { $member_price } {
		if { ! [empty_string_p $member_price] } {
		    append prices " / [ec_pretty_price $member_price]"
		}
	    }
	}
	
	# HAM : if the NoPayment parameter is set to "1" don't show the prices
	if { [parameter::get -package_id [ad_conn package_id] -parameter NoPayment -default 0] } {
		set prices ""
	}
    }

    set member_state [util_memoize [list dotlrn_ecommerce::section::member_state $user_id $community_id] $memoize_max_age]
    
    
    set waiting_p 0
    set pending_p 0
    set approved_p 0
    switch $member_state {
	"needs approval" {
	    set waiting_p 1
	    set waiting_list_number [util_memoize [list dotlrn_ecommerce::section::waiting_list_number $user_id $community_id] $memoize_max_age]
	}
	"application sent" {
	    set waiting_p 2
	    if { ![empty_string_p $assessment_id] } {
		set rel_id [db_string membership_rel {
		    select m.rel_id
		    from acs_rels r,
		    membership_rels m
		    where r.rel_id = m.rel_id
		    and r.object_id_one = :community_id
		    and r.object_id_two = :user_id
		    limit 1
		}]

		if { [db_0or1row assessment {
		    select m.session_id, completed_datetime
		    from dotlrn_ecommerce_application_assessment_map m, as_sessions s
		    where m.session_id = s.session_id
		    and rel_id = :rel_id
		    order by m.session_id desc
		    limit 1
		}] } {
		    set edit_asm_url [export_vars -base /assessment/assessment { assessment_id session_id }]
		    set cancel_url [export_vars -base application-reject { community_id user_id {send_email_p 0} {return_url $course_return_url} }]

		    if { ! [empty_string_p $completed_datetime] } {
			set review_asm_url [export_vars -base /assessment/session { session_id }]
			set asm_url [subst {
			    <a href="$review_asm_url" class="button">[_ dotlrn-ecommerce.review_application]</a>
			    <a href="$edit_asm_url" class="button">[_ dotlrn-ecommerce.lt_Edit_your_application]</a>
			    <a onclick="return confirm('Are you sure you want to cancel your application?')" href="$cancel_url" class="button">[_ dotlrn-ecommerce.lt_Cancel_your_applicati]</a>
			}]
		    } else {
			set asm_url [subst {
			    <a href="$shopping_cart_add_url" class="button">[_ dotlrn-ecommerce.lt_Your_application_is_i]</a>
			    <a href="$cancel_url" class="button">[_ dotlrn-ecommerce.lt_Cancel_your_applicati]</a>
			}]
		    }
		}
	    }
	}
	"request approval" {
	    set pending_p 1
	}
	"application approved" {
	    set approved_p 1
	    if {![empty_string_p $assessment_id]} {
		set rel_id [db_string membership_rel {
		    select m.rel_id
		    from acs_rels r,
		    membership_rels m
		    where r.rel_id = m.rel_id
		    and r.object_id_one = :community_id
		    and r.object_id_two = :user_id
		    limit 1
		}]

		if { [db_0or1row assessment {
		    select m.session_id, completed_datetime
		    from dotlrn_ecommerce_application_assessment_map m, as_sessions s
		    where m.session_id = s.session_id
		    and rel_id = :rel_id
		    order by m.session_id desc
		    limit 1
		}] } {
		    if { ! [empty_string_p $completed_datetime] } {
			set asm_url [export_vars -base /assessment/session { session_id }]
			set asm_url [subst {
			    <a href="$asm_url" class="button">[_ dotlrn-ecommerce.review_application]</a>
			}]
		    } else {
			set asm_url [export_vars -base /assessment/assessment { assessment_id session_id }]
			set asm_url [subst {<a href="$asm_url" class="button">[_ dotlrn-ecommerce.lt_Your_application_is_i]</a>}]
		    }
		}
	    }
	}
	"waitinglist approved" -
	"request approved" {
	    set approved_p 1
	}
    }

    # The above was the users waiting list and applications
    # Get the patron information

    set patron_message ""
    
    if {[lsearch $patron_communities $community_id] >= 0} {
	

    set patron_message [util_memoize [list dotlrn_ecommerce::patron_catalog_message $community_id  $user_id $product_id] $memoize_max_age]
    }

    # HAM : if we don't have an instructor id 
    set instructor_p -1
    if { [exists_and_not_null instructor_ids] } {
    	set instructor_p [lsearch $instructor_ids $user_id]
    } 

    set assessment_id [util_memoize [list dotlrn_ecommerce::section::application_assessment $section_id] $memoize_max_age]
    if { ! [empty_string_p $assessment_id] && $assessment_id != -1 } {
	set button "[_ dotlrn-ecommerce.apply_for_course]"
    }

    if {[catch {set fs_chunk [util_memoize [list uplevel dotlrn_ecommerce::section::fs_chunk $section_id] $memoize_max_age]} errmsg]} {
	ns_log notice "ERROR:DAVEB tree-chunk.tcl calling fs_chunk section_id='${section_id} \n tree_id = '${tree_id}' \n ------ \n $errmsg \n ----- \n'"
    }
    set description [ad_text_to_html $description]

    if { ! [dotlrn_ecommerce::util::param::get -default 1 ShowPriceOptionP] } {
	set show_price_p f
    }
    set section_edit_url [export_vars -base admin/one-section { course_id section_id }]
    set toggle_display_url [export_vars -base admin/toggle-display {section_id {return_url $course_return_url}}]
}

if {![info exists course_name]} {
    db_1row get_course "select * from dotlrn_catalog, cr_items where item_id=:course_id and course_id=latest_revision"
}

set course_edit_url [export_vars -base admin/course-info { course_id course_name course_key }]
