# packages/dotlrn-ecommerce/www/sections.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-17
    @arch-tag: ebe33d91-6940-42d6-9ca9-2e4d280f0233
    @cvs-id $Id$
} {
    course_id:integer,notnull
    {return_url index}
} -properties {
} -validate {
} -errors {
}

db_multirow -extend {community_url sessions member_price} section_list section_list { 
    select des.*, p.price 
    from dotlrn_ecommerce_section des, ec_products p, dotlrn_catalogi c
    where des.product_id = p.product_id
    and des.course_id = c.item_id
    and c.course_id = :course_id
} {
    set community_url [dotlrn_community::get_community_url $community_id]

    set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
    set calendar_url [calendar_portlet_display::get_url_stub $calendar_id]
    set item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id"]

    set sessions [join [db_list sessions {
	select to_char(start_date, 'Mon dd, yyyy hh:miam')
	from cal_items ci, acs_events e, acs_activities a, timespans s, time_intervals t
	where e.timespan_id = s.timespan_id
	and s.interval_id = t.interval_id
	and e.activity_id = a.activity_id
	and e.event_id = ci.cal_item_id
	and start_date >= current_date

	and ci.on_which_calendar = :calendar_id
	and ci.item_type_id = :item_type_id
    }] {<br />}]
    
    if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] } {
	db_0or1row member_price {
	    select sale_price as member_price
	    from ec_sale_prices
	    where product_id = :product_id
	    limit 1
	}
    }
}

template::list::create \
    -name section_list \
    -multirow section_list \
    -key section_id \
    -bulk_action_method post \
    -no_data "No Sections" \
    -elements {
	section_name {
	    label "Section Title"
	}
	sessions {
	    label "Sessions"
	    display_template {
		@section_list.sessions;noquote@
	    }
	}
	price {
	    label "Normal Price / Member Price"
	    html { align center }
	    display_template {
		$@section_list.price@<if @section_list.member_price@ not nil> / $@section_list.member_price@</if>
	    }
	}
	actions {
	    label Actions
	    html { align center }
	    display_template {
		<a href="/ecommerce/shopping-cart-add?product_id=@section_list.product_id@" class="button">add to cart</a>
	    }
	}
    }