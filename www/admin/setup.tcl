# /dotlrn-ecommerce/www/admin/setup.tcl
#  HAM : ham@solutiongrove.com (062205)
#  This script is called from ecwork.test

set package_id [ad_conn package_id]

# set the default template
parameter::set_value -parameter "DefaultMaster" -value "/www/mos-master" -package_id [subsite::main_site_id]

# enable member pricing
parameter::set_value -package_id $package_id -parameter "MemberPriceP" -value "1"

# *** COMMUNITIES ****

# create instructor and assistant community
# and set the parameters

set community_id [dotlrn_community::new \
			  -community_type dotlrn_club \
			  -object_type dotlrn_club \
			  -community_key "instructorcommunity" \
			  -pretty_name "Instructors Community"]
parameter::set_value -package_id $package_id -parameter "InstructorCommunityId" -value $community_id

set community_id [dotlrn_community::new \
			  -community_type dotlrn_club \
			  -object_type dotlrn_club \
			  -community_key "assistantcommunity" \
			  -pretty_name "Assistants Community"]
parameter::set_value -package_id $package_id -parameter "AssistantCommunityId" -value $community_id

# *** CATEGORIES ****

# create categories, set parameters and populate

set tree_id [category_tree::add -name "Grade"]
category_tree::map -tree_id $tree_id -object_id $package_id
parameter::set_value -package_id $package_id -parameter "GradeCategoryTree" -value $tree_id

set grades_list { "K" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "Pre-K" "Adult"}

foreach grade $grades_list {
	category::add -tree_id $tree_id -parent_id "" -name $grade
}

set tree_id [category_tree::add -name "Patron Relationships"]
category_tree::map -tree_id $tree_id -object_id $package_id
parameter::set_value -package_id $package_id -parameter "PatronRelationshipCategoryTree" -value $tree_id

set relationship_list { "Father" "Mother" "Son" "Daughter" "Brother" "Sister" "Aunt" "Uncle" "Grandmother" "Grandfather" "Other" }

foreach relation $relationship_list {
	category::add -tree_id $tree_id -parent_id "" -name $relation
}

set tree_id [db_string "get_catalog_id" "select object_id from acs_objects where title = 'dotlrn-course-catalog'"]

set course_type_list { "Family Course Today" "Technology" "Life Science" "Chemistry" "Exhibit Related" "Elder Hospital Program"}

foreach relation $course_type_list {
	category::add -tree_id $tree_id -parent_id "" -name $relation
}


ad_returnredirect "/"