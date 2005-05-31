ad_page_contract {
    custom for GWU. creates a class instance,
    a corresponding ecommerce product and necessary calendar items

    @author Deds Castillo
    @creation-date 2004-05-01
    @version $Id$
} {
    course_id:notnull
    section_id:optional
    {return_url "" }
}

dotlrn_catalog::get_course_data -course_id $course_id

set package_id [ad_conn package_id]

ad_form -name add_section -form {
    section_id:key
    {product_id:integer(hidden)}
    {return_url:text(hidden) {value $return_url}}
    {course_id:text(hidden) {value $course_id}}
    {section_name:text {label "Section Name"}}     
    {price:text(text) {label "Regular Price"} {html {size 6}} {section "Product Info"}} 
}


# HAM : Let's check if we have MemberPriceP enabled and set
# if it is let's add Member Price text
if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] } {
	ad_form -extend -name add_section -form {
		{ member_price:text(text),optional {label "Member Price"} {html {size 6}} }
	}
}

# HAM : Let's get the community id's for both Instructors and Assistants

set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]
set assistant_community_id [parameter::get -package_id [ad_conn package_id] -parameter AssistantCommunityId -default 0 ]

# HAM : Let's check if we have InstructorCommunityId enabled and set
if { $instructor_community_id == 0 && ![db_0or1row "checkinstructorcommunity" "select community_id from dotlrn_communities where community_id = :instructor_community_id"] } {
	ad_return_complaint 1 "Parameter InstructorCommunityId is not set or Community Id does not exist."
} else {
	# community_id is valid
	# list users
	set instructors [dotlrn_community::list_users  $instructor_community_id]
	set instructors_list [list]
	foreach instructor $instructors {
		set instructor_user_id [ns_set get $instructor user_id]
		set instructor_name "[ns_set get $instructor first_names] [ns_set get $instructor last_name]"
		lappend instructors_list [list $instructor_name $instructor_user_id ]
	}
	
	ad_form -extend -name add_section -form {
		{ instructors:string(multiselect),multiple {label "Instructors"} {options { $instructors_list } }	}
	}
}

# HAM : Let's check if we have AssistantCommunityId enabled and set
if { $assistant_community_id == 0 && ![db_0or1row "checkassistantcommunity" "select community_id from dotlrn_communities where community_id = :assistant_community_id"] } {
	ad_return_complaint 1 "Parameter AssistantCommunityId is not set or Community Id does not exist."
} else {
	# community_id is valid
	set assistants [dotlrn_community::list_users  $assistant_community_id]
	set assistants_list [list]
	foreach assistant $assistants {
		set assistant_user_id [ns_set get $assistant user_id]
		set assistant_name "[ns_set get $assistant first_names] [ns_set get $assistant last_name]"
		lappend assistants_list [list $assistant_name $assistant_user_id ]
	}
	
	ad_form -extend -name add_section -form {
		{ assistants:string(multiselect),multiple {label "Assistants"} {options { $assistants_list } }	}
	}

}


if { ! [ad_form_new_p -key section_id] } {
    db_1row community {
	select community_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }
    ad_form -extend -name add_section -form {
	{categories:integer(category),multiple,optional
	    {label "Categories"}
	    {html {size 4}}
	    {value "$community_id $package_id"}
	}
    }
} else {
    ad_form -extend -name add_section -form {
	{categories:integer(category),multiple,optional
	    {label "Categories"}
	    {html {size 4}}
	}
    }
}


# ecommerce stuff

set exclude_list [list "'classid'"]

db_foreach custom_fields_select "
    select field_identifier,
           field_name,
           default_value,
           column_type
    from ec_custom_product_fields
    where active_p='t'
          and field_identifier not in ([join $exclude_list ", "])
    order by creation_date" {
    # date
    if {[string equal $column_type date] || [string equal $column_type timestamp]} {
        if {[string equal $field_identifier enddate]} {
            ad_form -extend -name add_section -form [list \
							 [list "${field_identifier}:date,optional" {label $field_name} {value $default_value} {help_text "Not required for Distance Learning Courses"}]]
	} else {
	    ad_form -extend -name add_section -form [list \
							 [list "${field_identifier}:date,optional" {label $field_name} {value $default_value}] \
							]
	}
    } elseif {[string equal $column_type integer] || [string equal $column_type number]} {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(text),optional" {label $field_name} {value $default_value} {html {size 5}}] \
						    ]
    } elseif {[string equal $column_type "varchar(200)"]} {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(text),optional" {label $field_name} {value $default_value} {html {size 50 maxlength 200}}] \
						    ]
    } elseif {[string equal $column_type "varchar(4000)"]} {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(textarea),optional" {label $field_name} {value $default_value} {html {rows 4 cols 60}}] \
						    ]
    } else {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(radio),optional" {label $field_name} {value $default_value} {options {{t t} {f f}}}] \
						    ]
    }
}


ad_form -extend -name add_section -new_request {
    set product_id 0
} -edit_request {
    db_1row community {
	select des.*, p.price
	from dotlrn_ecommerce_section des, ec_products p
	where des.product_id = p.product_id
	and des.section_id = :section_id
    }

    db_1row custom_fields {
	select * from ec_custom_product_field_values where product_id = :product_id
    }
} -new_data {
    db_transaction {
        # create the class instance
	set community_id [dotlrn_club::new  -pretty_name "$course_data(name): Section $section_name"] 

	# HAM : Let's add chosen instructors in the role of instructors 
	# and assistants in the role of assistants
	foreach instructor $instructors {
		dotlrn_club::add_user -rel_type "dotlrn_club_instructor_rel" -community_id $community_id -user_id $instructor -member_state "approved"
	}
	foreach assistant $assistants {
		dotlrn_club::add_user -rel_type "dotlrn_member_rel" -community_id $community_id -user_id $assistant -member_state "approved"
	}
	
       
	# add the calendar item type "session"
	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	calendar::item_type_new -calendar_id $calendar_id -type "Session"


	# create an ecommerce product
	set product_id [db_nextval acs_object_id_seq]

	set user_id [ad_conn user_id]
	set context_id [ad_conn package_id]
        set product_name "$section_name"
        set sku ""
        set one_line_description "$section_name"
        set detailed_description ""
        set search_keywords ""
        set present_p "t"
        set stock_status ""
        # let's have dirname be the first four letters (lowercase) of the product_name
        # followed by the product_id (for uniqueness)
	regsub -all {[^a-zA-Z]} $product_name "" letters_in_product_name
	set letters_in_product_name [string tolower $letters_in_product_name]
	if [catch {set dirname "[string range $letters_in_product_name 0 3]$product_id"}] {
            #maybe there aren't 4 letters in the product name
            set dirname "$letters_in_product_name$product_id"
        }
	set color_list ""
        set size_list ""
	set peeraddr [ad_conn peeraddr]
	set product_id [db_exec_plsql product_insert {
            select ec_product__new(
				   :product_id,
				   :user_id,
				   :context_id,
				   :product_name,
				   :price,
				   :sku,
				   :one_line_description,
				   :detailed_description,
				   :search_keywords,
				   :present_p,
				   :stock_status,
				   :dirname,
				   to_date(now(), 'YYYY-MM-DD'),
				   :color_list,
				   :size_list,
				   :peeraddr
				   )
	}]

	db_dml product_update {
	    update ec_products
	    set active_p = 't'
	    where product_id = :product_id
	}
	# take care of custom fields
        # we have to generate audit information
        set audit_fields "last_modified, last_modifying_user, modified_ip_address"
        set audit_info "now(), :user_id, :peeraddr"
	
        # things to insert into ec_custom_product_field_values if they exist
	set custom_columns_to_insert [list product_id]
	set custom_column_values_to_insert [list ":product_id"]
	set bind_set [ns_set create]
        ns_set put $bind_set product_id $product_id
        ns_set put $bind_set user_id $user_id
        ns_set put $bind_set peeraddr $peeraddr
	
	db_foreach custom_columns_select {
            select field_identifier, column_type
            from ec_custom_product_fields
            where active_p='t'
	} {
	    if {[info exists $field_identifier] } {
                lappend custom_columns_to_insert $field_identifier
                lappend custom_column_values_to_insert ":$field_identifier"
		if {[string equal $column_type date] || [string equal $column_type timestamp]} {
		    set one_date [template::util::date::get_property linear_date_no_time [subst $$field_identifier]]
                    ns_set put $bind_set $field_identifier $one_date
		} else {
		    ns_set put $bind_set $field_identifier [subst $$field_identifier]
		}
	    }
	}
	db_dml custom_fields_insert "
        insert into ec_custom_product_field_values
        ([join $custom_columns_to_insert ", "], $audit_fields)
        values
        ([join $custom_column_values_to_insert ","], $audit_info)
        " -bind $bind_set

	#HAM: create a sale item from the member price
	# do so only if member price is provided
	# and MemberPriceP is 1
	if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] && [exists_and_not_null member_price]} {

		# HAM : FIXME

		# not sure if these values are correct
		# comment out when properly tested

		set sale_price_id [db_nextval ec_sale_price_id_sequence]
		set sale_price $member_price
		set offer_code ""
	
		db_dml sale_insert "
		insert into ec_sale_prices
		(sale_price_id, product_id, sale_price, sale_begins, sale_ends, sale_name, offer_code, last_modified, last_modifying_user, modified_ip_address)
		values
		(:sale_price_id, :product_id, :sale_price, to_date(now() - '1 day':: interval,'YYYY-MM-DD HH24:MI:SS'), to_date(now() + '99 years':: interval,'YYYY-MM-DD HH24:MI:SS'), 'MemberPrice', :offer_code, now(), :user_id, :peeraddr)"
	}

	#CM: We should probably add ecomerce_product_id to ecommerce_Section and insert it here.
	db_dml add_section {
	    insert into dotlrn_ecommerce_section(section_id, course_id, section_name, community_id,product_id) values
	    (:section_id, :course_id, :section_name, :community_id, :product_id)
	}

	# for this to work, dotlrn_eccomerce_section must be an object 
	# just use community_id DAVEB
	# where do the terms options come from?! DAVEB
	
	category::map_object -object_id $community_id $categories
    }

} -edit_data {
    db_dml update_section {
	update dotlrn_ecommerce_section set
	section_name = :section_name
	where section_id = :section_id
    }

    # Change the community's name
    dotlrn_community::set_community_name \
        -community_id $community_id \
        -pretty_name $section_name

    # Update price
    db_dml update_price {
	update ec_products set price = :price where product_id = :product_id
    }

    # things to insert into ec_custom_product_field_values if they exist
    set user_id [ad_conn user_id]
    set peeraddr [ad_conn peeraddr]
    set custom_columns_to_insert [list product_id]
    set custom_column_values_to_insert [list ":product_id"]
    set bind_set [ns_set create]
    ns_set put $bind_set product_id $product_id
    ns_set put $bind_set user_id $user_id
    ns_set put $bind_set peeraddr $peeraddr

    db_foreach custom_columns_select {
	select field_identifier, column_type
	from ec_custom_product_fields
	where active_p='t'
    } {
	if {[info exists $field_identifier] } {
	    lappend custom_columns_to_update "$field_identifier = :$field_identifier"
	    if {[string equal $column_type date] || [string equal $column_type timestamp]} {
		set one_date [template::util::date::get_property linear_date_no_time [subst $$field_identifier]]
		ns_set put $bind_set $field_identifier $one_date
	    } else {
		ns_set put $bind_set $field_identifier [subst $$field_identifier]
	    }
	}
    }
    db_dml custom_fields_insert "
        update ec_custom_product_field_values set [join $custom_columns_to_update ,] where product_id = :product_id
        " -bind $bind_set

    category::map_object -remove_old -object_id $community_id $categories
} -after_submit {
    ad_returnredirect $return_url
}


# Used by en_US version of new_class_instance message
set class_instances_pretty_name [parameter::get -localize -parameter class_instances_pretty_name]
set page_title "Add Section"
set context [list $page_title]