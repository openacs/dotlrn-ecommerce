ad_page_contract {
    Displays information of one course
    @author          Miguel Marin (miguelmarin@viaro.net) 
    @author          Viaro Networks www.viaro.net
    @creation-date   15-02-2005
} {
    course_id:notnull
    { index "" }
    { return_url "" }
} -validate {
    course_exists {
	# check if the course exists and set course_name and course_key
	if {![db_0or1row get_course "select course_name, course_key from dotlrn_catalog where course_id=:course_id"]} {
	    ad_return notfound
	}
    }
}

# TODO DaveB is there a Tcl proc for course info?

if { [string equal $index ""] } {
    set context [list [list "course-list" "[_ dotlrn-catalog.course_list]"] "[_ dotlrn-catalog.one_course_info]"]
} else {
    set context [list [list "../course-info?course_id=$course_id" "[_ dotlrn-catalog.one_course_info]"] "$course_name [_ dotlrn-catalog.course_info]"]
    set return_url "${return_url}&index=yes"
}

# Check permission over course_id
permission::require_permission -object_id $course_id -privilege "admin"

db_1row get_course_info { } 
set page_title "$course_key [_ dotlrn-catalog.course_info]"

set asm_name [db_string get_asm_name { } -default "[_ dotlrn-catalog.not_associated]"]
set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]
set creation_user [dotlrn_catalog::get_creation_user -object_id $item_id]
set rel [dotlrn_catalog::has_relation -course_id $course_id]


set dotlrn_url [dotlrn::get_url]
if { ![info exists index] } {
    set index ""
}

if { ![info exists to_index] } {
    set to_index ""
}

if { [info exist return_url] } {
    set return_url $return_url
} else {
    set return_url "course-info?course_id=$course_id&course_name=$name&course_key=$course_key"
}

if { ![info exists asmid] } {
    set asmid "-1"
}

if { ![info exists revision] } {
    set revision "no"
}

set category_p [db_string get_category { } -default -1]

set info $course_info
set name $course_name
set edit "yes"
set asm $asm_name
set info [ad_html_text_convert -from text/enhanced -to text/plain $info]

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
set tree_id [db_string get_tree_id { } -default "-1"]

# Get the category name
set category_name "[category::get_name [category::get_mapped_categories $course_id]]"

# Check if user has admin permission over course_id
set admin_p 0
if { [permission::permission_p -object_id $cc_package_id -privilege "create"] } { 
    set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]
    if { [permission::permission_p -object_id $course_id -privilege "admin"] } { 
	set admin_p 1
    } else {
	set admin_p 0
    }
}


set obj_n 0
set dotlrn_class "("
set dotlrn_com "("

# For dotlrn associations
db_multirow -extend { obj_n admin_p } relations relation { } {
    set obj_n 1
    if { [string equal $type "dotlrn_catalog_class_rel" ]} {
	append dotlrn_class "'$object_id'"
	append dotlrn_class ","
    } else {
	append dotlrn_com "'$object_id'"
	append dotlrn_com ","
    }
}
append dotlrn_class "0)"
append dotlrn_com "0)"

db_multirow classes_list get_dotlrn_classes { }

template::list::create \
    -name dotlrn_classes \
    -multirow classes_list \
    -key object_id \
    -row_pretty_plural "[_ dotlrn-catalog.dotlrn_classes]" \
    -elements {
        class  {
            label "[_ dotlrn-catalog.class_name]"
            display_template {
		<if $index not eq "">
                   <a href="dotlrn-info?object_id=@classes_list.object_id@&type=class&course_id=$course_id&course_name=$name&course_key=$course_key">@classes_list.pretty_name@</a> 
                </if> 
		<else>
		   <a href="../dotlrn-info?object_id=@classes_list.object_id@&type=class&course_id=$course_id&course_name=$name&course_key=$course_key">@classes_list.pretty_name@</a> 
		</else>
            }
        }
        dep_name {
            label "[_ dotlrn-catalog.dep_name]"
            display_template {
                @classes_list.department_name@
            }
        }
        term_name  {
            label "[_ dotlrn-catalog.term_name]"
            display_template {
                    @classes_list.term_name@
            }
        }
        subject  {
            label "[_ dotlrn-catalog.subject_name]"
            display_template {
                    @classes_list.class_name@
            }
        }
    }


db_multirow com_list get_dotlrn_communities { }


template::list::create \
    -name dotlrn_communities \
    -multirow com_list \
    -key object_id \
    -row_pretty_plural "[_ dotlrn-catalog.dotlrn_com]" \
    -elements {
        community  {
            label "[_ dotlrn-catalog.com_name]"
            display_template {
		<if $index not eq "">
                    <a href="dotlrn-info?object_id=@com_list.object_id@&type=community&course_id=$course_id&course_name=$name&course_key=$course_key">@com_list.pretty_name@</a>
		</if>
		<else>
                    <a href="../dotlrn-info?object_id=@com_list.object_id@&type=community&course_id=$course_id&course_name=$name&course_key=$course_key">@com_list.pretty_name@</a>
		</else>
            }
        }
    }


set return_url [ns_urlencode "course-info?course_id=$course_id&course_key=$course_key&course_name=$course_name"]


set community_url ""

db_multirow -extend {community_url calendar_url num_sessions attendees available_slots} section_list section_list { 
    select s.section_id, s.section_name, s.product_id, s.community_id, v.maxparticipants
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, ec_custom_product_field_values v
    where s.course_id = c.item_id
    and c.course_id = :course_id
    and s.product_id = v.product_id

    order by lower(s.section_name)
} {
    ns_log notice "DEBUG:: $section_name, $community_id"

    set community_url [dotlrn_community::get_community_url $community_id]

    set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]

    set calendar_url [calendar_portlet_display::get_url_stub $calendar_id]

    set item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id limit 1" -default 0]

    set num_sessions [db_string num_sessions "select count(cal_item_id) from cal_items where on_which_calendar = :calendar_id and item_type_id = :item_type_id"]

    db_1row attendees {
	select count(*) as attendees
	from dotlrn_member_rels_approved
	where community_id = :community_id
	and (rel_type = 'dotlrn_member_rel'
        or rel_type = 'dotlrn_club_student_rel')
    }

    if { ! [empty_string_p $maxparticipants] } {
	set available_slots [expr $maxparticipants - $attendees]
    }
}

template::list::create \
    -name section_list \
    -multirow section_list \
    -key section_id \
    -bulk_action_method post \
    -elements {
	name {
	    label "Name"
	    display_template {
		<a href=section-add-edit?course_id=$course_id&section_id=@section_list.section_id@&return_url=$return_url>@section_list.section_name@</a>
	    }
	}
	community {
	    label "Community"
	    display_template {
		<a href="@section_list.community_url;noquote@">User</a>-<a href="@section_list.community_url;noquote@/one-community-admin">Admin</a>
	    }
	}
	product {
	    label "Product"
	    display_template {
		<a href=/ecommerce/admin/products/one?product_id=@section_list.product_id@>Product</a>
	    }
	}
	registration {
	    label "Registration"
	    display_template {
		<a href=$community_url/members>Registrants</a><br>
		@section_list.attendees@ participant<if @section_list.attendees@ ne 1>s</if><if @section_list.available_slots@ not nil>,<br />@section_list.available_slots@ available</if>
	    }
	}
	num_sessions {
	    label "Sessions"
	    display_template {
		<a href=\"@section_list.calendar_url@/view?[export_vars -url {{view list} {period_days 365}}]\" target=new>@section_list.num_sessions@ Sessions</a> Scheduled.<br> <a href=\"@section_list.calendar_url@/cal-item-new?[export_vars -url {calendar_id item_type_id {view day}}]\" target=new>Add Session</a>
	    }
	}
	attendance {
	    label "Attendance"
	    display_template {
		<a href=@section_list.community_url@attendance/admin/>Attendance</a>
	    }
	}
	expenses {
	    label "Expenses"
	    display_template {
		<a href=@section_list.community_url@expense-tracking/admin/>Expenses</a>
	    }
	}
	members {
	    label "Purchases"
	    html { align center }
	    display_template {
		<a href="patrons?section_id=@section_list.section_id@">Patron</a><br>
		<a href="process-purchase?section_id=@section_list.section_id@">Participant</a><br>
		<a href="process-group-purchase?section_id=@section_list.section_id@">Group</a>
	    }
	}
	actions {
	    label "Actions"
	    display_template { <a href="section-delete?section_id=@section_list.section_id@&return_url=$return_url">Remove</a> }

         }
    }

# ad_form -name session -export { course_id return_url } -form {
#     {session_name:text {label "Session Name"}}
#     {session_description:text(textarea) {label "Section Description"} {html {cols 50 rows 5}}}
#     {typical_start_time:date {label "Typical Start Time"} {format {[lc_get formbuilder_time_format]}}}
#     {typical_end_time:date {label "Typical End Time"} {format {[lc_get formbuilder_time_format]}}}
#     original_url:text(hidden)
# } -on_request {
#     set original_url [ad_return_url]
# } -on_submit {

#     set typical_start_time [lindex $typical_start_time 3]:[lindex $typical_start_time 4]
#     set typical_end_time [lindex $typical_end_time 3]:[lindex $typical_end_time 4]

#     db_dml new_session {
# 	insert into dotlrn_ecommerce_predefined_sessions
# 	(course_item_id, session_name, session_description, typical_start_time, typical_end_time)
# 	values
# 	(:item_id, :session_name, :session_description, :typical_start_time, :typical_end_time)
#     }

# } -after_submit {
#     ad_returnredirect "$original_url#Sessions"
#     ad_script_abort
# }

# template::list::create \
#     -name sessions \
#     -multirow sessions \
#     -key session_id \
#     -bulk_actions {Delete predefined-session-delete Delete} \
#     -bulk_action_export_vars { {return_url "[ad_return_url]#Sessions"} } \
#     -elements {
# 	session_name {
# 	    label "Session Name"
# 	}
# 	session_description {
# 	    label "Session Description"
# 	}
# 	typical_start_time {
# 	    label "Typical Start Time"
# 	}
# 	typical_end_time {
# 	    label "Typical End Time"
# 	}
#     }

# db_multirow sessions sessions {
#     select session_id, session_name, session_description, to_char(typical_start_time, 'HH:MIAM') as typical_start_time, to_char(typical_end_time, 'HH:MIAM') as typical_end_time
#     from dotlrn_ecommerce_predefined_sessions
#     where course_item_id = :item_id
# }

catch {
    db_1row template_community {
	select c.community_id as template_community_id
	from dotlrn_catalogi c
	where c.course_id = :course_id
    }

    if { [empty_string_p $template_community_id] } {
	unset template_community_id
    } else {
	set template_community_url [dotlrn_community::get_community_url $template_community_id]
	set template_calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $template_community_id]
	set template_item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type='Session' and  calendar_id = :template_calendar_id limit 1" -default 0]
	set template_calendar_url [export_vars -base ${template_community_url}calendar/cal-item-new { {item_type_id $template_item_type_id} {calendar_id $template_calendar_id} {view day} }]
    }
}