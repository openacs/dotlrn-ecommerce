# packages/dotlrn-ecommerce/tcl/apm-callback-procs.tcl

ad_library {
    
    APM Callbacks
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-15
    @arch-tag: 14c74f81-76d3-4891-af33-8b63166ae80f
    @cvs-id $Id$
}

namespace eval dotlrn_ecommerce {}

ad_proc -private dotlrn_ecommerce::install {

} {
    After install callback
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-15
    
    @return 
    
    @error 
} {

    # add new rel types for student and instructors
    # Roel: Figure out why this is failing but dc_student_rel
    # is being created
    catch {
      rel_types::new -supertype dotlrn_member_rel -role_two instructor dc_instructor_rel "dotLRN Club Instructor" "dotLRN Club Instructors" dotlrn_club 0 "" user 0 ""
      rel_types::new -supertype dotlrn_member_rel -role_two student dc_student_rel "dotLRN Club Student" "dotLRN Club Students" dotlrn_club 0 "" user 0 ""
    }

    rel_types::new -role_one user -role_two user patron_rel "Patron" "Patrons" user 0 65535 user 0 65535

    # Associate a dotlrn_catalog course to an assessment session result
    rel_types::new -role_one d_catalog_role -role_two as_session_role d_catalog_as_session_rel "dotLRN Catalog Course to Assessment Session" "dotLRN Catalog Courses to Assessment Sessions" dotlrn_catalog 0 1 as_sessions 0 1

    # Associate an ecommerce product to an assessment session result
    rel_types::new -role_one as_session_role -role_two ec_product_role as_session_ec_product_rel "Assessment Session to ECommerce Product" "Assessment Sessions to ECommerce Products" as_sessions 0 1 ec_product 0 1

    rel_types::new -role_one member_rel_role -role_two user membership_patron_rel "Membership Patron" "Membership Patrons" dotlrn_member_rel 0 65535 user 0 65535

    set attribute_list [package_object_attribute_list -start_with dotlrn_catalog dotlrn_catalog]
    set sort_order [expr [llength $attribute_list] + 1]

    content::type::attribute::new \
	-content_type "dotlrn_catalog" \
	-attribute_name "community_id" \
	-datatype "integer" \
	-pretty_name "Template Community" \
	-sort_order $sort_order \
	-column_spec integer

    incr sort_order

    content::type::attribute::new \
	-content_type "dotlrn_catalog" \
	-attribute_name "display_p" \
	-datatype "boolean" \
	-pretty_name "Flag to display or hide course" \
	-sort_order $sort_order \
	-default_value "true" \
	-column_spec "boolean"

    # I think default_value does not set the default for the column so we do a db_dml 
    db_dml "update_default" "alter table dotlrn_catalog alter display_p set default 'true'"
}

ad_proc -private dotlrn_ecommerce::after_upgrade {
    -from_version_name
    -to_version_name
} {
    
    
    @author Hamilton Chua (hamilton.chua@gmail.com)
    @creation-date 2005-07-22
    
    @param from_version_name

    @param to_version_name

    @return 
    
    @error 
} {

    #apm_upgrade_logic \
    #    -from_version_name $from_version_name \
    #    -to_version_name $to_version_name \
    #    -spec {
    #	}
}

ad_proc -private dotlrn-catalog::package_mount {
    -package_id
    -node_id
} {
    create the category tree for terms
    
} {
    # To categorize courses
    set tree_id [category_tree::add -name "Terms"]
    category_tree::map -tree_id $tree_id -object_id $package_id

}
