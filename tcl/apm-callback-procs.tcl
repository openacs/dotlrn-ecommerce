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

	incr sort_order

	content::type::attribute::new \
		-content_type "dotlrn_catalog" \
		-attribute_name "auto_register_p" \
		-datatype "boolean" \
		-pretty_name "Auto Register" \
		-sort_order $sort_order \
		-default_value "false" \
		-column_spec "boolean"	

	# I think default_value does not set the default for the column so we do a db_dml 
	db_dml "update_default" "alter table dotlrn_catalog alter display_p set default 'true'"

}

ad_proc -private dotlrn_ecommerce::after_mount {
    -package_id
} {
    After mount callback
    
    @author Hamilton Chua (ham@solutiongrove.com)
    @creation-date 2006-02-23
    
    @return 
    
    @error 
} {

	# create instructor and assistant community
	# and set the parameters
	
	set community_id [dotlrn_community::new \
				-community_type dotlrn_club \
				-object_type dotlrn_club \
				-community_key "instructorcommunity" \
				-pretty_name "Instructors Community"]
	parameter::set_value -package_id $package_id -parameter "InstructorCommunityId" -value $community_id
	
	# change the "member" role to "instructor"
	
	dotlrn_community::set_role_pretty_data -community_id $community_id \
	-rel_type "dotlrn_member_rel" -role "member" -pretty_name "Instructor" \
	-pretty_plural "Instructors"
	
	set community_id [dotlrn_community::new \
				-community_type dotlrn_club \
				-object_type dotlrn_club \
				-community_key "assistantcommunity" \
				-pretty_name "Assistants Community"]
	parameter::set_value -package_id $package_id -parameter "AssistantCommunityId" -value $community_id
	
	# change the "member" role to "assistant"
	
	dotlrn_community::set_role_pretty_data -community_id $community_id \
	-rel_type "dotlrn_member_rel" -role "member" -pretty_name "Assistant Instructor" \
	-pretty_plural "Assistant Instructors"


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

    apm_upgrade_logic \
	-from_version_name $from_version_name \
	-to_version_name $to_version_name \
	-spec {
	    0.1d4 0.1d5 {
		apm_parameter_register \
		    MultipleItemDiscountP \
		    "Enable multiple item discounts, i.e. the first item has the full price and the next items get the discount." \
		    dotlrn-ecommerce \
		    0 \
		    number

		apm_parameter_register \
		    MultipleItemDiscountAmount \
		    "The amount discounted to multiple item purchases. This needs the parameter MultipleItemDiscountP to be set to 1." \
		    dotlrn-ecommerce \
		    5 \
		    number

		apm_parameter_register \
		    AdminCanOverrideWaitingListP \
		    "Allow the admin to override the waiting list if the section is full." \
		    dotlrn-ecommerce \
		    1 \
		    number
	    }
	    0.1d6 0.1d7 {
		apm_parameter_register \
		    GradePrerequisitesP \
		    "Set this to 1 if you want participants to be verified against the Grade requirement for a section." \
		    dotlrn-ecommerce \
		    0 \
		    number

		apm_parameter_register \
		    ShowSectionCategoryFields \
		    "Display the category field in the section add/edit form." \
		    dotlrn-ecommerce \
		    0 \
		    number
	    }
	    0.1d7 0.1d8 {
		apm_parameter_register \
		    GroupPurchaseP \
		    "Allow purchasing for groups." \
		    dotlrn-ecommerce \
		    1 \
		    number

		apm_parameter_register \
		    AllowSettingRelationshipsP \
		    "Support setting of related users." \
		    dotlrn-ecommerce \
		    1 \
		    number

		apm_parameter_register \
		    OfferCodesP \
		    "Support asking for offer codes for discount prices." \
		    dotlrn-ecommerce \
		    0 \
		    number

		apm_parameter_register \
		    AllowAheadAccess \
		    "Allow access to community after being accepted, even before registration." \
		    dotlrn-ecommerce \
		    0 \
		    number
	    }
	    0.1d23 0.1d24 {
		# check for missing guest rels
		# add them
		foreach user_id [db_list get_missing_rels "select du.user_id from
                dotlrn_users du left join
                dotlrn_guest_status dg
                on du.user_id=dg.user_id
                where dg.guest_p is null"] {
		    # for now I am assuming NON-GUEST
		    dotlrn_privacy::set_user_guest_p -user_id $user_id -value f
		}
	    }
    	}
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
