<?xml version="1.0"?>
<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.1</version>
  </rdbms>

	<fullquery name="get_item_type_id_template">
	<querytext>
		select item_type_id from cal_item_types where type='Session' and  calendar_id = :template_calendar_id limit 1
	</querytext>
	</fullquery>

	<fullquery name="get_item_type_id">
	<querytext>
		select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id limit 1
	</querytext>
	</fullquery>

	<fullquery name="member_price">
	<querytext>
	    select sale_price as member_price
	    from ec_sale_prices
	    where product_id = :product_id
	    limit 1
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
		coalesce(e.name, a.name) as session_name,
		'session_description',
		coalesce(e.status_summary, a.status_summary) as session_description,
		'start_date',
		to_char(start_date, 'yyyy-mm-dd'),
		'end_date',
		to_char(end_date, 'yyyy-mm-dd')
		from     acs_activities a,
		acs_events e,
		timespans s,
		time_intervals t,
		calendars cals,
		cal_items ci left join
		cal_item_types cit on cit.item_type_id = ci.item_type_id
		where    e.timespan_id = s.timespan_id
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
            select ec_product__new(
				   :product_id,
				   :user_id,
				   :context_id,
				   :product_name,
				   :price,
				   :sku,
				   :one_line_description,
				   :detailed_description,
				   :search_keywords,
				   :present_p,
				   :stock_status,
				   :dirname,
				   to_date(now(), 'YYYY-MM-DD'),
				   :color_list,
				   :size_list,
				   :peeraddr
				   )
	</querytext>
	</fullquery>

	<fullquery name="custom_fields_insert">
	<querytext>
		insert into ec_custom_product_field_values
		([join $custom_columns_to_insert ", "], last_modified, last_modifying_user, modified_ip_address)
		values
		([join $custom_column_values_to_insert ","], now(), :user_id, :peeraddr)
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
		(:sale_price_id, :product_id, :sale_price, to_date(now() - '1 day':: interval,'YYYY-MM-DD HH24:MI:SS'), to_date(now() + '99 years':: interval,'YYYY-MM-DD HH24:MI:SS'), 'MemberPrice', :offer_code, now(), :user_id, :peeraddr)
	</querytext>
	</fullquery>

	<fullquery name="sale_price">
	<querytext>
		select sale_price
		from ec_sale_prices
		where product_id = :product_id
		limit 1
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
