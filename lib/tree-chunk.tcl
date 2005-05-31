ad_page_contract {
    Display an ident tree of categories and courses.
    @author          Miguel Marin (miguelmarin@viaro.net)
    @author          Viaro Networks www.viaro.net
    @creation-date   11-02-2005

} {
    category_f:optional
    uncat_f:optional

    { level "" }

    { orderby course_name }
    { groupby course_name }
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

# Generate filters based on categories
set filters {
    category_f {
	label "[_ dotlrn-catalog.categories]"
	values { ${Course Type} }
	where_clause { ${Course Type_where_query} }
    }
    uncat_f {
	label "[_ dotlrn-catalog.uncat]"
	values { "Watch" }
	where_clause { dc.course_id not in ( select object_id from category_object_map where category_id in \
						 ( select category_id from categories where tree_id =:tree_id ))
	}
    }
}

set filter_list [list category_f]

set form [ns_getform]

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
set category_trees [linsert [category_tree::get_mapped_trees $package_id] 0 $tree_id]

set count 0
foreach tree_id $category_trees {

    set tree_id [lindex $tree_id 0]

    set tree_list [category_tree::get_tree -all $tree_id]
    set tree_length [llength $tree_list]

    db_1row get_tree_name {
	select name
	from category_trees t, category_tree_translations tt
	where t.tree_id = tt.tree_id
	and t.tree_id = :tree_id
    }

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

    if { $count == 0 } {
	set f category_f
    } else {
	regsub -all { } $name _ f
	set f [string tolower $f]_f
    }

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
    
    if { $count == 0 } {
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
    incr count
}

foreach tree [category_tree::get_mapped_trees $package_id] {
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

# Section categories
#foreach section_tree [category_tree::get_mapped_trees $package_id] {
#    set tree_list [category_tree::get_tree -all $section_tree]
#}

# 	age_description_f {
# 	    label "Age Description"
# 	    values { ${Age Description} }
# 	    where_clause { ${Age Description_where_query} }
# 	}

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]
template::list::create \
    -name course_list \
    -multirow course_list \
    -key course_id \
    -pass_properties { admin_p } \
    -actions {"View All" ? "View All"} \
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
	section_name {
	    label ""
	    display_template {
		<if @course_list.section_id@ not nil>
		<if @admin_p@ eq 1 or @course_list.member_p@ eq 1>
		<b>Section <a href="@course_list.community_url;noquote@">@course_list.section_name@</a></b>
		</if>
		<else>
		<b>Section @course_list.section_name@</b>
		</else>
		<if @course_list.section_grades@ not nil> (@course_list.section_grades@)</if>
		<if @course_list.sessions@ not nil><br />@course_list.sessions;noquote@</if>
		<if @course_list.instructors@ not nil><br />@course_list.instructors;noquote@</if>
		<if @course_list.prices@ not nil><br />@course_list.prices;noquote@</if>
	    }
	    html { width 50% }
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
		<if @course_list.member_p@ eq 0>
		(<a href="/ecommerce/shopping-cart-add?product_id=@course_list.product_id@">add to cart</a>)
		</if>

		<if @admin_p@ eq 1>
		(<a href="@course_list.section_edit_url;noquote@">edit</a>)
		</if>
		</if>
	    }
	    html { width 50% }
	}
    } -orderby {
	course_name {
	    orderby course_name
	}
    } -groupby {
	label "Group by"
	type multivar
	values {
	    { { <if @admin_p@ eq 1>(<a href="admin/course-info?course_id=@course_list.course_id@">info</a>) (<a href="@course_list.course_edit_url;noquote@">edit</a>) (<a href="admin/section-add-edit?course_id=@course_list.course_id@&return_url=/dotlrn-ecommerce/index">add section</a>)</if>
		<br />@course_list.course_grades@
		<blockquote>
		@course_list.course_info;noquote@
		</blockquote>}
		{ {groupby course_name} {orderby course_name} } }
	}
    }


set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]
set _instructors [dotlrn_community::list_users $instructor_community_id]
if { [llength $_instructors] == 0 } {
    set _instructors 0
} else {
    foreach instructor $_instructors {
	lappend __instructors [ns_set get $instructor user_id]
    }
}
set grade_tree_id [db_string grade_tree {
    select tree_id
    from category_tree_translations 
    where name = 'Grade'
} -default 0]

db_multirow -extend { category_name community_url course_edit_url section_edit_url course_grades section_grades sections_url member_p sessions instructors prices } course_list get_courses { } {
#     set mapped [category::get_mapped_categories $course_id]

#     foreach element $mapped {
# 	append category_name "[category::get_name $element], "
#     }

    set category_name [string range $category_name 0 [expr [string length $category_name] - 3]]
    set community_url [dotlrn_community::get_community_url $community_id]
    set return_url [ad_return_url]
    set course_edit_url [export_vars -base admin/course-add-edit { course_id return_url }]
    set section_edit_url [export_vars -base admin/section-add-edit { course_id section_id return_url }]
    set sections_url [export_vars -base sections { course_id }]

    set member_p [dotlrn_community::member_p $community_id $user_id]
    
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

	set sessions [util_memoize [list dotlrn_ecommerce::section::sessions $calendar_id]]

	set instructors [util_memoize [list dotlrn_ecommerce::section::instructors $community_id $__instructors]]

	if { [llength $instructors] == 1 } {
	    set instructors "Instructor: [join $instructors ", "] (<a href=\"${community_url}facilitator-bio\">view bio</a>)"
	} elseif { [llength $instructors] > 1 } {
	    set instructors "Instructors: [join $instructors ", "] (<a href=\"${community_url}facilitator-bio\">view bios</a>)"
	} else {
	    set instructors ""
	}
    }

    if { ! [empty_string_p $product_id] } {
	db_1row price {
	    select price as prices
	    from ec_products
	    where product_id = :product_id
	}
	if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] } {
	    if { [db_0or1row member_price {
		select sale_price as member_price
		from ec_sale_prices
		where product_id = :product_id
		limit 1
	    }] } {
		if { ! [empty_string_p $member_price] } {
		    append prices " / $member_price"
		}
	    }
	}
	
	set prices \$$prices
    }
}