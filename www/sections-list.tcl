ad_page_contract {
    List of course sections in a course catalog.

    @author Katie Lau (Katie.Lau # gmail.com)
	
    @creation-date 2007-06-22
    #@arch-tag: ebe33d91-6940-42d6-9ca9-2e4d280f0233
    #@cvs-id $Id$ 	
} {
	section_identifiers:optional
	orderby:optional
}

# require administrative permissions
set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege "admin"

template::list::create \
    -name sections_list \
    -multirow sections_list \
	-key section_identifier \
	-bulk_actions [list "Set Section Identifiers" "applications" "Set Section Identifiers"] \
	-bulk_action_click_function "set_section_identifiers" \
	-elements {	
		course_name {
		    label "Course Name"
		}
		pretty_name {
		    label "Section Name"
		}
		section_identifier {
		    label "Section Identifier (Key)"
		}
		active_start_date {
			label "Start Date"
		}
		active_end_date {
			label "End Date"
		}
	} \
	-orderby {
		course_name {
			orderby "dc.course_name"
		}
		pretty_name {
		    orderby "dca.pretty_name"
		}
		section_identifier {
			orderby "section_identifier"
		}
		active_start_date {
			orderby "dca.active_start_date"
		}
		active_end_date {
			orderby "dca.active_end_date"
		}		
	}	

db_multirow \
    -extend {
	#edit_url
	#delete_url
    } sections_list sections_select {
	
    } {
	#set edit_url [export_vars -base "news-edit" {item_id}]
	#set delete_url [export_vars -base "news-delete" {item_id}]
    }



 
