# packages/dotlrn-ecommerce/www/application-bulk-payments.tcl

ad_page_contract {
    
    Bulk payments
    
    @author Roel Canicula (roel@solutiongrove.com)
    @creation-date 2006-03-15
    @arch-tag: 7e28fd03-d828-4adb-b86b-4cf01769a9ee
    @cvs-id $Id$
} {
    {rel_id:multiple {}}
    return_url

    {method cc}
    {internal_account ""}
} -properties {
} -validate {
} -errors {
}

db_multirow already_registered already_registered [subst {
    select person__name(r.user_id) as person_name, t.course_name||': '||s.section_name as section_name

    from dotlrn_member_rels_full r, 
    dotlrn_ecommerce_section s,
    dotlrn_catalogi t,
    cr_items i

    where rel_id in ([join $rel_id ,])
    and r.community_id = s.community_id
    and s.course_id = t.item_id
    and t.course_id = i.live_revision
    and r.member_state = 'approved'
}]

if { [template::multirow size already_registered] > 0 } {
    set registered_exists_p 1

    template::list::create \
	-name already_registered \
	-multirow already_registered \
	-elements {
	    person_name {
		label "[_ dotlrn-ecommerce.Applicant]"
	    }
	    section_name {
		label "[_ dotlrn-ecommerce.Section]"
	    }
	}
} else {
    set registered_exists_p 0
}

set user_id [auth::require_login]
set user_session_id [ec_get_user_session_id]

if {![ad_secure_conn_p]} {
    if { ![ec_ssl_available_p] } {
	ad_return_error "[_ dotlrn-ecommerce.No_SSL_available]" "[_ dotlrn-ecommerce.lt_Were_sorry_but_we_can].
		    "
	ad_script_abort
    } else {
	set secure_url "[ec_secure_location][ns_conn url]"
	set vars_to_export [ec_export_entire_form_as_url_vars_maybe]
	if { ![empty_string_p $vars_to_export] } {
	    set secure_url "$secure_url?$vars_to_export"
	}

	ad_returnredirect $secure_url
	ad_script_abort
    }
}

ec_create_new_session_if_necessary [export_url_vars rel_id:multiple return_url]
ec_log_user_as_user_id_for_this_session

# Build bulk payment list
ad_form -name applications -export { return_url } -form {
    {back:text(button) {label Back} {html {onclick "window.location = 'applications'"}}}
    {submit:text(submit) {label Submit}}
}

# Determine supported payment methods
if { [empty_string_p [set payment_methods [parameter::get -parameter PaymentMethods]]] } {
    lappend payment_methods cc
}

set method_count 0
set new_payment_methods [list]
set validate [list]
foreach payment_method [split $payment_methods] {
    set _payment_method [split $payment_method :]
    if { [llength $_payment_method] == 2 } {
	lappend new_payment_methods [set payment_method [lindex $_payment_method 0]]

	switch [lindex $_payment_method 1] {
	    admin {
		if { $admin_p } {
		    set ${payment_method}_p 1
		} else {
		    continue
		}
	    }
	}
    } else {
	set ${payment_method}_p 1
	lappend new_payment_methods $payment_method
    }

    switch $payment_method {
	internal_account {
	    lappend method_options [list "[_ dotlrn-ecommerce.lt_Internal_account_numb]" internal_account]
	    lappend validate {internal_account
		{ [exists_and_not_null internal_account] || [template::element::get_value applications method] != "internal_account" }
		"[_ dotlrn-ecommerce.lt_Please_enter_an_inter]"
	    }
	}
	check {
	    lappend method_options [list "[_ dotlrn-ecommerce.Check]" check]
	}
	cc {
	    lappend method_options [list "[_ dotlrn-ecommerce.Credit_Card]" cc]
	    lappend validate {creditcard_number
		{ [template::element::get_value applications method] != "cc" || [exists_and_not_null creditcard_number] }
		"[_ dotlrn-ecommerce.lt_Please_enter_a_credit]"
	    }
	    lappend validate {creditcard_type
		{ [template::element::get_value applications method] != "cc" || [exists_and_not_null creditcard_type] }
		"[_ dotlrn-ecommerce.lt_Please_select_a_credi]"
	    }
	    lappend validate {creditcard_expires
		{ [template::element::get_value applications method] != "cc" || ([exists_and_not_null creditcard_expire_1] && [exists_and_not_null creditcard_expire_2]) }
		"[_ dotlrn-ecommerce.lt_A_full_credit_card_ex]"
	    }
	}
	cash {
	    lappend method_options [list "[_ dotlrn-ecommerce.Cash]" cash]
	}
	invoice {
	    lappend method_options [list "[_ dotlrn-ecommerce.Invoice]" invoice]
	}
	scholarship {
	    # Purchasing via scholarships should only be available to
	    # admins by logic, but this can be set in the param
	    lappend method_options [list "[_ dotlrn-ecommerce.Scholarship]" scholarship]
	}
	lockbox {
	    lappend method_options [list "[_ dotlrn-ecommerce.Lock_Box]" lockbox]
	}
    }
    incr method_count
}
set payment_methods $new_payment_methods

if { $method_count > 1 } {
    ad_form -extend -name applications -form {
	{-section "[_ dotlrn-ecommerce.Payment_Information]"}
	{method:text(radio) {label "[_ dotlrn-ecommerce.Select]"} {options {$method_options}}}
    }

    if { [exists_and_equal internal_account_p 1] } {
	ad_form -extend -name applications -form {
	    {internal_account:text,optional {label "[_ dotlrn-ecommerce.Internal_Account]"}}
	}
    }
} elseif { $method_count == 1 } {
    ad_form -extend -name applications -export { {method "[lindex [split $payment_methods] 0]"} } -form {}
} else {
    ad_form -extend -name applications -export { {method cc} } -form {}
}

if { [info exists cc_p] } {
    if { $method_count == 1 } {
	# The creditcard_expires field is a hack, improve it
	ad_form -extend -name applications -form {
	    {creditcard_number:text {label "[_ dotlrn-ecommerce.Credit_card_number]"}}
	    {creditcard_type:text(select) {label "[_ dotlrn-ecommerce.Type]"} {options {{"[_ dotlrn-ecommerce.Please_select_one]" ""} {VISA v} {MasterCard m} {"American Express" a}}}}
	    {creditcard_expires:text(inform) {label "[_ dotlrn-ecommerce.Expires] <span class=\"form-required-mark\">*</span>"} {value $ec_expires_widget}}
	}
    } else {
	ad_form -extend -name applications -form {
	    {-section "[_ dotlrn-ecommerce.lt_Credit_card_informati]"}
	    {creditcard_number:text,optional {label "[_ dotlrn-ecommerce.Credit_card_number]"}}
	    {creditcard_type:text(select),optional {label Type} {options {{"[_ dotlrn-ecommerce.Please_select_one]" ""} {VISA v} {MasterCard m} {"American Express" a}}}}
	    {creditcard_expires:text(inform),optional {label "[_ dotlrn-ecommerce.Expires]"} {value $ec_expires_widget}}
	}
    }
}

template::list::create \
    -name applications \
    -multirow applications \
    -elements {
	person_name {
	    label "[_ dotlrn-ecommerce.Applicant]"
	}
	section_name {
	    label "[_ dotlrn-ecommerce.Section]"
	}
	regular_price {
	    label "[_ dotlrn-ecommerce.Regular_Price]"
	    html { align center }
	    display_template {
		<if @applications.free_p@>
		Free
		</if>
		<else>
		@applications.pretty_price;noquote@
		</else>
	    }
	}
	new_price {
	    label "[_ dotlrn-ecommerce.New_Price]"
	    display_template {		    
		<input type="text" name="bulk_payment_@applications.rel_id@" value="@applications.regular_price@" />
	    }
	}
    } \
    -filters {
	rel_id {}
	return_url {}
    }

db_multirow -extend { regular_price free_p pretty_price } applications applications [subst {
    select r.rel_id, r.user_id, person__name(r.user_id) as person_name, t.course_name||': '||s.section_name as section_name, s.product_id

    from dotlrn_member_rels_full r, dotlrn_ecommerce_section s
    left join ec_products p
    on (s.product_id = p.product_id),
    dotlrn_catalogi t,
    cr_items i

    where rel_id in ([join $rel_id ,])
    and r.community_id = s.community_id
    and s.course_id = t.item_id
    and t.course_id = i.live_revision
    and r.member_state != 'approved'
}] {
    set regular_price [format "%.2f" [lindex [ec_lowest_price_and_price_name_for_an_item $product_id $user_id] 0]]
    set free_p [expr {$regular_price == 0}]
    set pretty_price [ec_pretty_price $regular_price]
}

ad_form -extend -name applications -validate $validate -form {} -on_submit {

    # Actually register and record payments
    set _form [rp_getform]
    array set form [util_ns_set_to_list -set $_form]

    template::multirow create applications_registered rel_id price valid_p order_id person_name section_name

    foreach name [array names form] {
	if { [regexp {^bulk_payment_(\d+)$} $name match one_rel_id] } {
	    # Check if price is valid
	    set new_price $form($match)
	    if { [string is double $new_price] && $new_price >= 0 } {
		# Register the user
		if { [db_0or1row get_rel_info {
		    select r.user_id as participant_id, r.community_id, s.product_id, o.creation_user as patron_id, person__name(r.user_id) as person_name, t.course_name||': '||s.section_name as section_name
		    from dotlrn_member_rels_full r, dotlrn_ecommerce_section s, acs_objects o, dotlrn_catalogi t, cr_items i
		    
		    where r.community_id = s.community_id
		    and r.rel_id = o.object_id
	    	    and s.course_id = t.item_id
		    and t.course_id = i.live_revision
		    and r.rel_id = :one_rel_id
		}] } {
			# Check if this is a free course
			if { $new_price > 0 } {

			    # Use user_id to the patron to be used in the
			    # ecommerce SQL calls since the patron is paying
			    set user_id $patron_id

			    # Check for an existing order in this session
			    if { ! [db_0or1row existing_order {
				select order_id
				from ec_orders
				where user_session_id = :user_session_id
				and order_state = 'in_basket'
			    }] } {
				ns_log notice "application-bulk-payments: no existing order in session $user_session_id"

				# Create an order entry		    			
				set order_id [db_nextval ec_order_id_sequence]

				# Create the order (if an in_basket order *still* doesn't exist)
				db_dml insert_new_ec_order {
				    insert into ec_orders
				    (order_id, user_session_id, order_state, in_basket_date)
				    select :order_id, :user_session_id, 'in_basket', current_timestamp 
				    where not exists (select 1 from ec_orders where user_session_id=:user_session_id and order_state='in_basket')
				}
			    } else {
				ns_log notice "application-bulk-payments: existing order_id $order_id in session $user_session_id"
			    }

			    # Check for an existing item in this order,
			    # there can be more than one
			    set existing_item_p 0
			    db_foreach existin_items {
				select product_id as existing_product_id, item_id as existing_item_id
				from ec_items
				where order_id = :order_id
			    } {
				if { $product_id == $existing_product_id } {
				    ns_log notice "application-bulk-payments: existing product $product_id with item_id $existing_item_id in order $order_id"

				    set existing_item_p 1
				} else {
				    ns_log notice "application-bulk-payments: unrecognized product $product_id in order $order_id"

				    # Delete the item that doesn't match,
				    # this should not happen and we need to
				    # delete it or the order will be inaccurate
				    db_dml delete_unmatched_item {
					delete from ec_items
					where item_id = :existing_item_id
				    }
				}
			    }

			    if { ! $existing_item_p } {
				ns_log notice "application-bulk-payments: product $product_id doesn't exist in order $order_id, creating"

				set item_id [db_nextval ec_item_id_sequence]

				set color_choice [set size_choice [set style_choice ""]]
				db_dml insert_new_item_in_order {
				    insert into ec_items
				    (item_id, product_id, color_choice, size_choice, style_choice, order_id, in_cart_date, price_charged)
				    select :item_id, :product_id, :color_choice,
				    :size_choice, :style_choice, :order_id, current_timestamp, :new_price
				    from dual
				}

				db_dml insert_new_item_order_dotlrn_ecommerce {
				    insert into dotlrn_ecommerce_orders (item_id, patron_id, participant_id)
				    values (:item_id, :user_id, :participant_id)
				}


				if { $method == "cc" } {
				    if { [db_0or1row check_transaction {
					select 1
					from dotlrn_ecommerce_transactions
					where order_id = :order_id
				    }] } {
					db_dml update_transaction_check {
					    update dotlrn_ecommerce_transactions
					    set method = 'cc',
					    internal_account = null
					    where order_id = :order_id
					}
				    } else {
					db_dml save_transaction_check {
					    insert into dotlrn_ecommerce_transactions
					    (order_id, method)
					    values
					    (:order_id, 'cc')
					}
				    }
				} else {
				    # Other payment methods
				    # Just store it
				    if { $method == "internal_account" } {
					# Check if internal account was entered
					if { [empty_string_p $internal_account] } {
					    ad_return_complaint 1 "<li> [_ dotlrn-ecommerce.lt_Please_enter_an_inter_1]</li>"
					    ad_script_abort		
					}

					if { [db_0or1row check_transaction {
					    select 1
					    from dotlrn_ecommerce_transactions
					    where order_id = :order_id
					}] } {
					    db_dml update_transaction_internal_account {
						update dotlrn_ecommerce_transactions
						set method = 'internal_account',
						internal_account = :internal_account
						where order_id = :order_id
					    }
					} else {
					    db_dml save_transaction_internal_account {
						insert into dotlrn_ecommerce_transactions
						(order_id, method, internal_account)
						values
						(:order_id, 'internal_account', :internal_account)
					    }
					}
				    } elseif { $method == "check" ||
					       $method == "cash" ||
					       $method == "invoice" ||
					       $method == "scholarship" ||
					       $method == "lockbox"
					   } {
					if { [db_0or1row check_transaction {
					    select 1
					    from dotlrn_ecommerce_transactions
					    where order_id = :order_id
					}] } {
					    db_dml update_transaction_check {
						update dotlrn_ecommerce_transactions
						set method = :method,
						internal_account = null
						where order_id = :order_id
					    }
					} else {
					    db_dml save_transaction_check {
						insert into dotlrn_ecommerce_transactions
						(order_id, method)
						values
						(:order_id, :method)
					    }
					}
				    }
				}
			    }

			    set use_member_price_p 0
			    if {[parameter::get -parameter MemberPriceP -default 0]} {
				set ec_category_id [parameter::get -parameter "MembershipECCategoryId" -default ""]
				set group_id [parameter::get -parameter MemberGroupId -default 0]
				if {$group_id} {
				    set use_member_price_p [group::member_p -group_id $group_id -user_id $user_id]
				}

				if {$use_member_price_p} {
				    set offer_code [db_string get_offer_code {
					select offer_code
					from ec_sale_prices
					where product_id = :product_id
					and offer_code = 'dotlrn-ecommerce'
				    } -default ""]
				    if {![empty_string_p $offer_code]} {
					# DEDS: at this point we need to insert or update an offer
					set offer_code_exists_p [db_string get_offer_code_p {
					    select count(*) 
					    from ec_user_session_offer_codes 
					    where user_session_id=:user_session_id
					    and product_id=:product_id
					}]
					if {$offer_code_exists_p} {
					    db_dml update_ec_us_offers {
						update ec_user_session_offer_codes 
						set offer_code = :offer_code
						where user_session_id = :user_session_id
						and product_id = :product_id
					    }
					} else {
					    db_dml inert_uc_offer_code {
						insert into ec_user_session_offer_codes
						(user_session_id, product_id, offer_code) 
						values 
						(:user_session_id, :product_id, :offer_code)
					    }
					}
				    }
				}
				# DEDS
				# at this point if user is purchasing
				# a member product then we probably need to adjust
				# any other products in basket
				if {[parameter::get -parameter MemberPriceP -default 0]} {
				    if {![empty_string_p $ec_category_id]} {
					if {[db_string membership_product_p {
					    select count(*)
					    from ec_category_product_map
					    where category_id = :ec_category_id
					    and product_id = :product_id
					}]} {
					    dotlrn_ecommerce::ec::toggle_offer_codes -order_id $order_id -insert
					}
				    }
				}
			    }

			    # Register the user

			    ec_update_state_to_confirmed $order_id 
			    ec_update_state_to_authorized $order_id 
			    callback -- ecommerce::after-checkout -user_id $user_id -patron_id $user_id -order_id $order_id
			} else {
			    dotlrn_ecommerce::registration::new -user_id $participant_id \
				-patron_id $user_id \
				-community_id $community_id

			    set order_id ""
			}

			template::multirow append applications_registered $one_rel_id [ec_pretty_price $form($match)] 1 $order_id $person_name $section_name
		} else {
		    template::multirow append applications_registered $one_rel_id "[_ dotlrn-ecommerce.lt_There_was_a_problem_r]" 0 "" $person_name $section_name
		}

	    } else {
		template::multirow append applications_registered $one_rel_id "[_ dotlrn-ecommerce.Invalid_price]: $form($match)" 0 "" $person_name $section_name
	    }
	}
    }
    
    template::list::create \
	-name applications_registered \
	-multirow applications_registered \
	-actions [list "[_ dotlrn-ecommerce.Back_to_Applications]" $return_url "[_ dotlrn-ecommerce.Back_to_Applications]"] \
	-elements {
	    order_id {
		label "[_ dotlrn-ecommerce.Order_ID]"
		html { align center }
	    }
	    person_name {
		label "[_ dotlrn-ecommerce.Applicant]"
	    }
	    section_name {
		label "[_ dotlrn-ecommerce.Section]"
	    }
	    price {
		label "[_ dotlrn-ecommerce.Price_Charged]"
		html { align center }
	    }
	}
}