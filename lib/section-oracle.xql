<?xml version="1.0"?>

<queryset>
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>


	<fullquery name="get_item_type_id">
	<querytext>
		select item_type_id from cal_item_types where type='Session' and  calendar_id = :template_calendar_id and rownum = 1
	</querytext>
	</fullquery>

	<fullquery name="member_price">
	<querytext>
	    select sale_price as member_price
	    from ec_sale_prices
	    where product_id = :product_id and rownum = 1
	</querytext>
	</fullquery>

	<fullquery name="sessions">
	<querytext>
		select   'cal_item_id',
		ci.cal_item_id,
		'typical_start_time',
		to_char(start_date,'HH24:MI') as typical_start_time,
		'typical_end_time',
		to_char(end_date,'HH24:MI') as typical_end_time,
		'session_name',
		nvl(e.name, a.name) as session_name,
		'session_description',
		nvl(e.status_summary, a.status_summary) as session_description,
		'start_date',
		to_char(start_date, 'yyyy-mm-dd'),
		'end_date',
		to_char(end_date, 'yyyy-mm-dd')
		from acs_activities a,
		acs_events e,
		timespans s,
		time_intervals t,
		calendars cals,
		cal_items ci,
		cal_item_types cit 
		where    cit.item_type_id(+) = ci.item_type_id
		and	 e.timespan_id = s.timespan_id
		and      s.interval_id = t.interval_id
		and      e.activity_id = a.activity_id
		and      ci.cal_item_id= e.event_id
		and      cals.calendar_id = ci.on_which_calendar
		and      e.event_id = ci.cal_item_id
		and	 ci.on_which_calendar = :template_calendar_id
		and      ci.item_type_id = :template_item_type_id
	</querytext>
	</fullquery>

	<fullquery name="product_insert">
	<querytext>
        begin
        :1 := ec_product.new(product_id => :product_id,
		object_type => 'ec_product',
		creation_date => sysdate,
		creation_user => :user_id,
		creation_ip => :peeraddr,
		context_id => :context_id,
		product_name => :product_name,
		price => :price,
		sku => :sku,
		one_line_description => :one_line_description,
		detailed_description => :detailed_description,
		search_keywords => :search_keywords,
		present_p => :present_p,
		stock_status => :stock_status,
		dirname => :dirname,
		available_date => to_date(sysdate, 'YYYY-MM-DD'),
		color_list => :color_list,
		size_list => :size_list,
		style_list => '',
		email_on_purchase_list => '',
		url => '',
		no_shipping_avail_p => '',
		shipping => '',
		shipping_additional => '',
		weight => '',
		active_p => 't',
		template_id => ''
        );
        end;
	</querytext>
	</fullquery>

	<fullquery name="custom_fields_insert">
	<querytext>
		insert into ec_custom_product_field_values
		([join $custom_columns_to_insert ", "], last_modified, last_modifying_user, modified_ip_address)
		values
		([join $custom_column_values_to_insert ","], sysdate, :user_id, :peeraddr)
	</querytext>
	</fullquery>

	<fullquery name="custom_fields_update">
	<querytext>
		update ec_custom_product_field_values set [join $custom_columns_to_update ,] where product_id = :product_id
	</querytext>
	</fullquery>

	<fullquery name="sale_insert">
	<querytext>
      		insert into ec_sale_prices
		(sale_price_id, product_id, sale_price, sale_begins, sale_ends, sale_name, offer_code, last_modified, last_modifying_user, modified_ip_address)
		values
		(:sale_price_id, :product_id, :sale_price, to_date(sysdate,'YYYY-MM-DD HH24:MI:SS'), to_date(sysdate+99,'YYYY-MM-DD HH24:MI:SS'), 'MemberPrice', :offer_code, sysdate, :user_id, :peeraddr)
	</querytext>
	</fullquery>

	<fullquery name="sale_price">
	<querytext>
		select sale_price
		from ec_sale_prices
		where product_id = :product_id and rownum = 1
	</querytext>
	</fullquery>

	<fullquery name="set_member_price">
	<querytext>
		    update ec_sale_prices
		    set sale_price = :member_price
		    where product_id = :product_id
	</querytext>
	</fullquery>

</queryset>