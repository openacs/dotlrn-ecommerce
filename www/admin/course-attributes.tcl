# packages/dotlrn-ecommerce/www/admin/course-attributes.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-24
    @arch-tag: 787e3cbd-2eb2-4e8e-8ba6-8fde9a2643de
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

set attribute_list [package_object_attribute_list -start_with dotlrn_catalog dotlrn_catalog]

ns_log notice "DEBUG:: ATTRIBUTES:: $attribute_list"

template::multirow create attributes attribute_id name title sort_order widget

set count 1
foreach attribute $attribute_list {
    template::multirow append attributes \
	[lindex $attribute 0] \
	[lindex $attribute 2] \
	[lindex $attribute 3] \
	$count \
	[lindex $attribute 4]

    incr count
}

template::list::create \
    -name attributes \
    -key name \
    -elements {
	name {
	    label Name
	}
	title {
	    label Title
	}
	widget {
	    label Datatype
	}
    } \
    -multirow attributes \
    -actions {Add course-attribute-add Add} \
    -bulk_actions {Delete course-attributes-delete Delete}