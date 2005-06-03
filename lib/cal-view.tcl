ad_page_contract {
    Display an ident tree of categories and courses.
    @author          Miguel Marin (miguelmarin@viaro.net)
    @author          Viaro Networks www.viaro.net
    @creation-date   11-02-2005

} {
    category_f:optional
    uncat_f:optional

    { level "" }
    { date "" }
    { orderby course_name }
    { groupby course_name }
}

set calendar_id_list [list]

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]
set filters [list]
set view calendar

# Generate filters based on categories
lappend filters category_f {
	label "[_ dotlrn-catalog.categories]"
	values { ${Course Type} }
	where_clause { ${Course Type_where_query} }
    } uncat_f {
	label "[_ dotlrn-catalog.uncat]"
	values { "Watch" }
	where_clause { dc.course_id not in ( select object_id from category_object_map where category_id in \
						 ( select category_id from categories where tree_id =:tree_id ))
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

set filters [linsert $filters 0 date {} view {
	label "View"
	values { {List ""} {"" ""} }
}]
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

db_multirow course_list get_courses { } {

    if { ! [empty_string_p $community_id] } {

	# Build sessions
	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	lappend calendar_id_list $calendar_id

    }
}

set date 
set item_template "one-course?cal_item_id=\$item_id"
set export [list]
foreach {name discard} $filters {
    lappend export $name
}
set next_month_template "[export_vars -no_empty -base . $export]&date=\[ad_urlencode \$next_month\]"
set prev_month_template "[export_vars -no_empty -base . $export]&date=\[ad_urlencode \$prev_month\]"