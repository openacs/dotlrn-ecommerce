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
    rel_types::new -supertype dotlrn_member_rel -role_two student dotlrn_club_student_rel "dotLRN Club Student" "dotLRN Club Students" dotlrn_club 0 "" user 0 ""
    rel_types::new -supertype dotlrn_member_rel -role_two instructor "dotLRN Club Instructor" "dotLRN Club Instructors" dotlrn_club 0 ""D user 0 ""

    rel_types::new -role_one user -role_two user patron_rel "Patron" "Patrons" user 0 65535 user 0 65535

    # Associate a dotlrn_catalog course to an assessment session result
    rel_types::new -role_one d_catalog_role -role_two as_session_role d_catalog_as_session_rel "dotLRN Catalog Course to Assessment Session" "dotLRN Catalog Courses to Assessment Sessions" dotlrn_catalog 0 1 as_sessions 0 1

    # Associate an ecommerce product to an assessment session result
    rel_types::new -role_one as_session_role -role_two ec_product_role as_session_ec_product_rel "Assessment Session to ECommerce Product" "Assessment Sessions to ECommerce Products" as_sessions 0 1 ec_product 0 1
}

ad_proc -private dotlrn-catalog::package_mount {
    -package_id
    -node_id
} {
    create the category tree for terms
    
} {
    # To categorize courses
    set tree_id [category_tree::add -name "dotlrn-section-terms"]
    category_tree::map -tree_id $tree_id -object_id $package_id
}
