ad_page_contract {
    Display an ident tree of categories and courses.
    @author          Miguel Marin (miguelmarin@viaro.net)
    @author          Viaro Networks www.viaro.net
    @creation-date   11-02-2005

} {
    category_f:optional
    uncat_f:optional

    { level "" }
    instructor:optional
    { orderby course_name }
    { groupby course_name }
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]

set filters {}

# Generate filters based on categories
# set filters {
#     uncat_f {
# 	label "[_ dotlrn-catalog.uncat]"
# 	values { "Watch" }
# 	where_clause { dc.course_id not in ( select object_id from category_object_map where category_id in \
# 						 ( select category_id from categories where tree_id =:tree_id ))
# 	}
#     }
# }

set filter_list [list category_f]

set form [rp_getform]

set category_trees [concat [category_tree::get_mapped_trees $cc_package_id] [category_tree::get_mapped_trees $package_id]]
set course_categories [list]
set section_categories [list]

foreach tree [category_tree::get_mapped_trees $cc_package_id] {
    set tree_name [lindex $tree 1]
    regsub -all { } $tree_name _ f
    set f [string tolower $f]_f

    ns_log notice "DEBUG:: CATEGORY:: $tree_name"

    lappend filter_list $f
    set ff [ns_set get $form $f]

    if { ! [empty_string_p $ff] } {
	set $f $ff
    }
    lappend course_categories [lindex $tree 0]
}
foreach tree [category_tree::get_mapped_trees $package_id] {
    set tree_name [lindex $tree 1]
    regsub -all { } $tree_name _ f
    set f [string tolower $f]_f

    ns_log notice "DEBUG:: CATEGORY:: $tree_name"

    lappend filter_list $f
    set ff [ns_set get $form $f]

    if { ! [empty_string_p $ff] } {
	set $f $ff
    }
    lappend section_categories [lindex $tree 0]
}

ns_log notice "DEBUG:: FILTER:: $filter_list"

foreach f $filter_list {
    if { [info exists $f] } {
	set var_list [split [set $f] "&"]
	set ${f}_category_v [lindex $var_list 0]
	set ${f}_level [lindex [split [lindex $var_list 1] "="] 1]
    } else {
	set ${f}_category_v ""
	set ${f}_level ""
    }

    ns_log notice "DEBUG:: VARS:: category_v [set ${f}_category_v], level [set ${f}_level]"
}

if { ! [empty_string_p $level] } {
    set category_f_level $level
}

# Get all tree categories
#set category_trees [linsert [category_tree::get_mapped_trees $package_id] 0 $tree_id]
#set category_trees [category_tree::get_mapped_trees $cc_package_id]

foreach tree_id $category_trees {

    set tree_id [lindex $tree_id 0]

    set tree_list [category_tree::get_tree -all $tree_id]
    set tree_length [llength $tree_list]

    db_1row get_tree_name { }

    # Create a list of values for the list filter
    set $name [list]

    foreach element $tree_list {
	set ident [lindex $element 3]
	set spacer ""
	for { set i 1 } { $i < $ident } { incr i } {
	    append spacer ". . "
	}
	lappend $name [list "${spacer}[lindex "$element" 1]" "[lindex $element 0]&level=[lindex $element 3]" ]
    }

    regsub -all { } $name _ f
    set f [string tolower $f]_f

    # Get all sub categories
    set map_tree "("
    if { ![string equal [set ${f}_level] ""] } {
	ns_log notice "DEBUG:: SUBCATEGORIES:: $f, $tree_length"
	
	set j 0
	set i 0
	while { $i < $tree_length } {
	    set element [lindex $tree_list $i]
	    if {[string equal [set ${f}_category_v] [lindex $element 0]] } {
		append map_tree "[lindex $element 0],"
		set pos $i
		set i $tree_length
	    }
	    incr i
	}
	set j 0
	set i [expr $pos + 1]
	while { $i < $tree_length } {
	    set element [lindex $tree_list $i]
	    if { [set ${f}_level] < [lindex $element 3] } {
		append map_tree "[lindex $element 0],"
		incr i
	    } else {
		set i $tree_length
	    }
	}
	append map_tree "0)"
    }
    
    if { [lsearch $course_categories $tree_id] != -1 } {
	if { [string equal $[set ${f}_category_v] ""] } {
	    set ${name}_where_query "dc.course_id in ( select object_id from category_object_map_tree where tree_id = $tree_id )" 
	} else {
	    set ${name}_where_query "dc.course_id in ( select object_id from category_object_map_tree where tree_id = $tree_id and category_id in $map_tree )"
	}
    } else {
	if { [string equal $[set ${f}_category_v] ""] } {
	    set ${name}_where_query "dec.community_id in ( select object_id from category_object_map_tree where tree_id = $tree_id )" 
	} else {
	    set ${name}_where_query "dec.community_id in ( select object_id from category_object_map_tree where tree_id = $tree_id and category_id in $map_tree )"
	}
    }
}

foreach tree $category_trees {
    set tree_name [lindex $tree 1]
    regsub -all { } $tree_name _ f
    set f [string tolower $f]_f

    lappend filters "$f" \
	[list \
	     label "$tree_name" \
	     values "[set $tree_name]" \
	     where_clause "[set ${tree_name}_where_query]"
	]
}

set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]
set _instructors [dotlrn_community::list_users $instructor_community_id]

set __instructors [list]
if { [llength $_instructors] == 0 } {
    set _instructors 0
    set instructors_filter ""
} else {
    foreach _instructor $_instructors {
	lappend __instructors [ns_set get $_instructor user_id]
	lappend instructors_filter [list "[ns_set get $_instructor first_names] [ns_set get $_instructor last_name]" [ns_set get $_instructor user_id]]
    }
}

lappend filters instructor \
    [list \
	 label "[_ dotlrn-ecommerce.Instructor]" \
	 values $instructors_filter \
	 where_clause_eval {subst {exists (select 1
     from dotlrn_users u, dotlrn_member_rels_approved r
     where u.user_id = r.user_id
     and r.community_id = dec.community_id
     and r.rel_type = 'dotlrn_admin_rel'
     and r.user_id in ([join $instructor ,]))}}]
# Section categories
#foreach section_tree [category_tree::get_mapped_trees $package_id] {
#    set tree_list [category_tree::get_tree -all $section_tree]
#}

# 	age_description_f {
# 	    label "Age Description"
# 	    values { ${Age Description} }
# 	    where_clause { ${Age Description_where_query} }
# 	}

set filters [linsert $filters 0 view {
    label "[_ dotlrn-ecommerce.View]"
    values { {Calendar "calendar"} }
}]

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]

set actions [list]

lappend actions "[_ dotlrn-ecommerce.View_All]" ? "[_ dotlrn-ecommerce.View_All]"

if { $admin_p } {
    lappend actions "[_ dotlrn-ecommerce.Add_Course]" admin/course-add-edit "[_ dotlrn-ecommerce.Add_Course]"
}

template::list::create \
    -name course_list \
    -multirow course_list \
    -key course_id \
    -pass_properties { admin_p } \
    -actions $actions \
    -filters $filters \
    -bulk_action_method post \
    -bulk_action_export_vars {
    }\
    -row_pretty_plural "[_ dotlrn-catalog.courses]" \
    -elements {
	course_key  {
	    label "[_ dotlrn-catalog.course_key]"
	    display_template {
		<div align=left>
		<a href="sections?course_id=@course_list.course_id@">@course_list.course_key@</a> 
		</div>
	    }
	    hide_p 1
	}
	name  {
	    label "[_ dotlrn-catalog.course_name]"
	    display_template {
		<div align=left>
	        @course_list.course_name@
		</div>
	    }
	    hide_p 1
	}
	spacing {
	    label ""
	    display_template {
	    }
	    html { width 10% bgcolor=white }
	}
	section_name {
	    label ""
	    
	    display_template {
		<if @course_list.section_id@ not nil> 
		<if @admin_p@ eq 1 or @course_list.member_p@ eq 1>
		<b>Section: <a href="@course_list.community_url;noquote@">@course_list.section_name@</a></b>
		</if>
		<else>
		<b>Section @course_list.section_name@</b>
		</else>

		<if @course_list.section_grades@ not nil> (@course_list.section_grades@)</if>
		<if @course_list.sessions@ not nil><br />@course_list.sessions;noquote@</if>
		<if @course_list.instructors@ not nil><br />@course_list.instructors;noquote@</if>
		<if @course_list.prices@ not nil><br />@course_list.prices;noquote@</if>
		<br />@course_list.attendees;noquote@ participant<if @course_list.attendees@ gt 1>s</if>
		<if @course_list.available_slots@ not nil and @course_list.available_slots@ gt 0>,<br />@course_list.available_slots;noquote@ available</if>
		</if>
	    }
	    html { width 40% }
	}
	category {
	    label "[_ dotlrn-catalog.category]"
	    display_template {
		<div align=center>
		<if @course_list.category_name@ not eq "">
		@course_list.category_name@
		</if>
		<else>
		#dotlrn-catalog.uncat#
		</else>
		</div>
	    }
	    hide_p 1
	}
	actions {
	    label ""
	    display_template {
		<if @course_list.member_p@ eq 0 and @course_list.pending_p@ eq 0 and @course_list.prices@ ne "">
		<a href="@course_list.shopping_cart_add_url;noquote@" class="button">[_ dotlrn-ecommerce.add_to_cart]</a>
		</if>

		<if @course_list.prices@ eq "">
		<a href="@course_list.shopping_cart_add_url;noquote@" class="button">[_ dotlrn-ecommerce.register]</a>
		</if>
		
		<if @admin_p@ eq 1>
		<a href="@course_list.section_edit_url;noquote@" class="button">[_ dotlrn-ecommerce.edit]</a>
		</if>

		<if @course_list.pending_p@ eq 1>
		<font color="red">(application pending)</font>
		</if>
	    }
	    html { width 40% nowrap }
	}
    } -orderby {
	course_name {
	    orderby course_name
	}
    } -groupby {
	label "Group by"
	type multivar
	values {
	    { { <a name="@course_list.course_key@" /><if @admin_p@ eq 1><a href="admin/course-info?course_id=@course_list.course_id@" class="button">[_ dotlrn-ecommerce.info]</a> <a href="@course_list.course_edit_url;noquote@" class="button">[_ dotlrn-ecommerce.edit]</a> <a href="@course_list.section_add_url;noquote@" class="button">[_ dotlrn-ecommerce.add_section]</a></if>
		<br />@course_list.course_grades@
	       <p>
		@course_list.course_info;noquote@
		<p>
		
	    }
		{ {groupby course_name} {orderby course_name} } }
	}
    }


set grade_tree_id [parameter::get -package_id [ad_conn package_id] -parameter GradeCategoryTree -default 0]

db_multirow -extend { category_name community_url course_edit_url section_add_url section_edit_url course_grades section_grades sections_url member_p sessions instructors prices shopping_cart_add_url attendees available_slots pending_p } course_list get_courses { } {
#     set mapped [category::get_mapped_categories $course_id]

#     foreach element $mapped {
# 	append category_name "[category::get_name $element], "
#     }

    set category_name [string range $category_name 0 [expr [string length $category_name] - 3]]
    set community_url [dotlrn_community::get_community_url $community_id]
    set return_url [ad_return_url]
    set course_edit_url [export_vars -base admin/course-add-edit { course_id return_url }]
    set section_add_url [export_vars -base admin/section-add-edit { course_id return_url }]
    set section_edit_url [export_vars -base admin/section-add-edit { course_id section_id return_url }]
    set sections_url [export_vars -base sections { course_id }]

    # HAM : check NoPayment parameter
    # if we're not asking for payment, change shopping cart url
    # to dotlrn-ecommerce/register
    if { [parameter::get -package_id [ad_conn package_id] -parameter NoPayment -default 0] } {
	set shopping_cart_add_url [export_vars -base register/ { community_id product_id}]
    } else {
    	set shopping_cart_add_url [export_vars -base ecommerce/shopping-cart-add { user_id product_id }]
    }

    set member_p [dotlrn_community::member_p $community_id $user_id]
    set pending_p [dotlrn_community::member_pending_p -community_id $community_id -user_id $user_id]
    
    set section_grades ""
    set course_grades ""
    set sessions ""
    set instructors ""
    set prices ""

    array unset arr_sessions

    if { ! [empty_string_p $community_id] } {

	# List grades
	set locale [ad_conn locale]
	set section_grades [util_memoize [list dotlrn_ecommerce::section::section_grades $community_id $grade_tree_id]]

	if { [llength $section_grades] == 1 } {
	    set section_grades "Grade [join $section_grades ", "]"
	} elseif { [llength $section_grades] > 1 } {
	    set section_grades "Grades [join $section_grades ", "]"
	} else {
	    set section_grades ""
	}

	set course_grades [util_memoize [list dotlrn_ecommerce::section::course_grades $item_id $grade_tree_id]]

	set letters [lsearch -all -inline -regexp $course_grades {[[:alpha:]]+}]
	set numbers [lsearch -all -inline -regexp $course_grades {\d+}]
	set numbers [lsort -integer $numbers]
	set course_grades [concat $letters $numbers]

	if { [llength $course_grades] == 1 } {
	    set course_grades "Grade [join $course_grades ", "]"
	} elseif { [llength $course_grades] > 1 } {
	    set course_grades "Grades [join $course_grades ", "]"
	} else {
	    set course_grades ""
	}

	# Build sessions
	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	lappend calendar_id_list $calendar_id
	set sessions [util_memoize [list dotlrn_ecommerce::section::sessions $calendar_id]]

	set instructors [util_memoize [list dotlrn_ecommerce::section::instructors $community_id $__instructors]]

	if { [llength $instructors] == 1 } {
	    set instructors "Instructor: [join $instructors ", "]"
	} elseif { [llength $instructors] > 1 } {
	    set instructors "Instructors: [join $instructors ", "]"
	} else {
	    set instructors ""
	}
	if { ! [empty_string_p $instructors] && $member_p } {
	    append instructors " <a href=\"${community_url}facilitator-bio\" class=\"button\">[_ dotlrn-ecommerce.view_bios]</a>"
	}

	db_1row attendees { }

	if { ! [empty_string_p $maxparticipants] } {
	    set available_slots [expr $maxparticipants - $attendees]
	}
    }

    if { ! [empty_string_p $product_id] } {
	db_1row price { }
	if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] } {
	    if { [db_0or1row member_price {   }] } {
		if { ! [empty_string_p $member_price] } {
		    append prices " / $member_price"
		}
	    }
	}
	
	set prices \$$prices

	# HAM : if the NoPayment parameter is set to "1" don't show the
	if { [parameter::get -package_id [ad_conn package_id] -parameter NoPayment -default 0] } {
		set prices ""
	}
    }
}