# packages/dotlrn-ecommerce/www/admin/section-edit.tcl

ad_page_contract {

    Edit a section

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2005-05-16
    
} -query {
    section_id:integer,notnull
    {return_url ""}
} -properties {
    page_title
    context
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

#permission::require_permission \
    -party_id $user_id \
    -object_id $section_id \
    -privilege "write"

ad_form -name section-edit \
    -export { return_url } \
    -form {
    section_id:key
	{product_id:text(hidden)}
	{course_id:text(hidden)}
	{community_id:text(hidden)}
    {section_name:text {label "Section Name"}}     
    {price:text(text) {label "Regular Price"} {html {size 6}} {section "Product Info"}} 
    {terms:integer(category),multiple,optional
	{label "Terms"}
	{html {size 4}}
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
            ad_form -extend -name section-edit -form [list \
							 [list "${field_identifier}:date,optional" {label $field_name} {value $default_value} {help_text "Not required for Distance Learning Courses"}]]
	} else {
	    ad_form -extend -name section-edit -form [list \
							 [list "${field_identifier}:date,optional" {label $field_name} {value $default_value}] \
							]
	}
    } elseif {[string equal $column_type integer] || [string equal $column_type number]} {
	ad_form -extend -name section-edit -form [list \
						     [list "${field_identifier}:text(text),optional" {label $field_name} {value $default_value} {html {size 5}}] \
						    ]
    } elseif {[string equal $column_type "varchar(200)"]} {
	ad_form -extend -name section-edit -form [list \
						     [list "${field_identifier}:text(text),optional" {label $field_name} {value $default_value} {html {size 50 maxlength 200}}] \
						    ]
    } elseif {[string equal $column_type "varchar(4000)"]} {
	ad_form -extend -name section-edit -form [list \
						     [list "${field_identifier}:text(textarea),optional" {label $field_name} {value $default_value} {html {rows 4 cols 60}}] \
						    ]
    } else {
	ad_form -extend -name section-edit -form [list \
						     [list "${field_identifier}:text(radio),optional" {label $field_name} {value $default_value} {options {{t t} {f f}}}] \
						    ]
    }
}


ad_form -extend -name section-edit \
    -edit_request {
	# fill in the form
	db_1row get_section "select * from dotlrn_ecommerce_section where section_id=:section_id"
	# get price from product
	db_1row get_product "select price from ec_products where product_id=:product_id"
	# get custom fields
	db_1row get_custom_values "select * from ec_custom_product_field_values where product_id=:product_id"
	# get categoriees
	element set_properties section-edit terms -category_object_id $community_id
    } -edit_data {
	db_transaction {
	    set bind_set [ns_set create]
	    ns_set put $bind_set product_id $product_id
	    ns_set put $bind_set user_id $user_id
	    ns_set put $bind_set peeraddr [ad_conn peeraddr]

	    db_foreach custom_columns_select {
		select field_identifier, column_type
		from ec_custom_product_fields
		where active_p='t'
	    } {
		if {[info exists $field_identifier] } {
		    lappend custom_columns  "${field_identifier}=:${field_identifier}"
		    if {[string equal $column_type date] || [string equal $column_type timestamp]} {
			set one_date [template::util::date::get_property linear_date_no_time [subst $$field_identifier]]
			ns_set put $bind_set $field_identifier $one_date
		    } else {
			ns_set put $bind_set $field_identifier [subst $$field_identifier]
		    }
		}
	    }
	    db_dml custom_fields_update "
                update ec_custom_product_field_values set [join $custom_columns ","] where product_id=:product_id
            " -bind $bind_set


	    db_dml update_product {
		update ec_products set price=:price where product_id=:product_id
	    }
	db_dml update_section {
	   update dotlrn_ecommerce_section set section_name=:section_name where section_id=:section_id
	}
	    # attach categories to the community_id or product_id, we have plenty of objects to work with!
	    # it works, but I can't get the terms values to display as selected.
	    # where is the options for the terms form element set!? DAVEB
	    if { ![string equal $terms "-1"] } {
		category::map_object -remove_old -object_id $community_id $terms
	    }

	}
    } -after_submit {
	if {[string equal "" $return_url]} {
	    set return_url [export_vars -base "course-info" {course_id}]
	}
	ad_returnredirect $return_url
	ad_script_abort
    }

set page_title "Edit Section"
set context [list $page_title]

ad_return_template
