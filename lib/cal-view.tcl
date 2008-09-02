ad_page_contract {
    Display an ident tree of categories and courses.
    @author          Miguel Marin (miguelmarin@viaro.net)
    @author          Viaro Networks www.viaro.net
    @creation-date   11-02-2005

} {
    course_type_f:optional
    category_f:optional
    uncat_f:optional
    grade_f:optional
    terms_f:optional
    zone_f:optional
    instructor:optional
    { level "" }
    { date "" }
    { view "calendar" }
    
    { orderby course_name }
    { groupby course_name }

    {period_days 31}
} -validate {
    date_not_before {
	if {[clock scan $date] < [clock scan "2004-01-01"]} {
	    ad_return_complaint 1 "That date is not available."
	    ad_script_abort
	}
    }
}


set currently_viewing "Currently Viewing:"

if { [exists_and_not_null course_type_f] } { append currently_viewing " Course Type"}
if { [exists_and_not_null grade_f] } { append currently_viewing ", Grade"}
if { [exists_and_not_null terms_f] } { append currently_viewing ", Terms"}
if { [exists_and_not_null zone_f] } { append currently_viewing ", Zone"}
if { [exists_and_not_null zone_f] } { append currently_viewing ", Instructor"}

set calendar_id_list [list]

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

    ns_log debug "DEBUG:: CATEGORY:: $tree_name"

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

    ns_log debug "DEBUG:: CATEGORY:: $tree_name"

    lappend filter_list $f
    set ff [ns_set get $form $f]

    if { ! [empty_string_p $ff] } {
	set $f $ff
    }
    lappend section_categories [lindex $tree 0]
}

ns_log debug "DEBUG:: FILTER:: $filter_list"

foreach f $filter_list {
    if { [info exists $f] } {
	set var_list [split [set $f] "&"]
	set ${f}_category_v [lindex $var_list 0]
	set ${f}_level [lindex [split [lindex $var_list 1] "="] 1]
    } else {
	set ${f}_category_v ""
	set ${f}_level ""
    }

    ns_log debug "DEBUG:: VARS:: category_v [set ${f}_category_v], level [set ${f}_level]"
}

if { ! [empty_string_p $level] } {
    set category_f_level $level
}

# Get all tree categories
#set category_trees [linsert [category_tree::get_mapped_trees $package_id] 0 $tree_id]
#set category_trees [category_tree::get_mapped_trees $cc_package_id]

# Display only categories with associated courses/sections
set show_used_categories_only_p [parameter::get -package_id [ad_conn package_id] -parameter ShowUsedCategoriesOnlyP -default "0"]

if { $show_used_categories_only_p } {
    set used_categories [db_list used_categories {
	select distinct category_id
	from (

	      select category_id
	      from categories c
	      where exists (select 1
			    from category_object_map
			    where category_id in (select category_id
						  from categories
						  where left_ind > c.left_ind
						  and right_ind < c.right_ind))
	      union

	      select category_id
	      from category_object_map

	      ) c
    }]
}

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
	if { ! $show_used_categories_only_p || [lsearch $used_categories [lindex $element 0]] != -1 } {
	    set ident [lindex $element 3]
	    set spacer ""
	    for { set i 1 } { $i < $ident } { incr i } {
		append spacer ". . "
	    }
	    lappend $name [list "${spacer}[lindex "$element" 1]" "[lindex $element 0]&level=[lindex $element 3]" ]
	}
    }


    regsub -all { } $name _ f
    set f [string tolower $f]_f

    # Get all sub categories
    set map_tree "("
    if { ![string equal [set ${f}_level] ""] } {
	ns_log debug "DEBUG:: SUBCATEGORIES:: $f, $tree_length"
	
	set j 0
	set i 0
	set pos 0
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
if { [llength $_instructors] == 0 } {
    set _instructors 0
    set instructors_filter ""
} else {
    foreach _instructor $_instructors {
	lappend __instructors [ns_set get $_instructor user_id]
	lappend instructors_filter [list "[ns_set get $_instructor first_names] [ns_set get $_instructor last_name]" [ns_set get $_instructor user_id]]
    }
}

# lappend filters instructor \
#     [list \
# 	 label "Instructor" \
# 	 values $instructors_filter \
# 	 where_clause_eval {subst {exists (select 1
#      from dotlrn_users u, dotlrn_member_rels_approved r
#      where u.user_id = r.user_id
#      and r.community_id = dec.community_id
#      and r.rel_type = 'dotlrn_ecom_instructor_rel'
#      and r.user_id in ([join $instructor ,]))}}]

set filters [linsert $filters 0 date {} view {
    label "View"
    values { {List ""} }
}]

#ns_log notice " *** $grade_f ***"

if { [exists_and_not_null course_type_f] || [exists_and_not_null grade_f] || [exists_and_not_null terms_f] || [exists_and_not_null zone_f]|| [exists_and_not_null instructor] } {
	set show_view_all "1"
} else {
	set show_view_all "0"
}


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
set item_template "one-section?cal_item_id=\$item_id"
set export [list]
foreach {name discard} $filters {
    lappend export $name
}

set next_month_template "[export_vars -exclude {date} -no_empty -base . $export]&date=\[ad_urlencode \$next_month\]"
set prev_month_template "[export_vars -exclude {date} -no_empty -base . $export]&date=\[ad_urlencode \$prev_month\]"

set view [parameter::get -default month -parameter CalendarView]