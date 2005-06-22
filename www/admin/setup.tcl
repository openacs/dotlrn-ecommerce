# /dotlrn-ecommerce/www/admin/setup.tcl
#  HAM : ham@solutiongrove.com (062205)
#  This script is called from ecwork.test

set package_id [ad_conn package_id]

# set the default template
parameter::set_value -parameter "DefaultMaster" -value "/www/mos-master" -package_id [subsite::main_site_id]

# create instructor and assitant community
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

# create category and set parameter
set tree_id [category_tree::add -name "Grade"]
category_tree::map -tree_id $tree_id -object_id $package_id
parameter::set_value -package_id $package_id -parameter "GradeCategoryTree" -value $tree_id

# populate categories with data


# populate courses

ad_returnredirect "/"