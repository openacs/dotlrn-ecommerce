-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d17-0.1d18.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-09-14
-- @arch-tag: 7e661079-1f4b-472a-9ffd-170aca6f03c8
-- @cvs-id $Id$
--

create view dlec_sections as (
	select s.*,
	v.maxparticipants,
	(v.maxparticipants - s.attendees) as available_slots,
	(s.attendees::float / v.maxparticipants * 100) as attendance_percentage
	from (select *,
	      (select count(*)
	       from dotlrn_member_rels_approved
	       where community_id = s.community_id
	       and rel_type in ('dotlrn_member_rel', 'dc_student_rel')) as attendees
	      from dotlrn_ecommerce_section s) s
	left join ec_custom_product_field_values v
	on (s.product_id = v.product_id)
);

create view dlec_members as (
 	select to_char(o.authorized_date, 'yyyy-mm-dd hh:miam') as authorized_date, p.product_name, u.user_id, u.first_names, u.last_name, u.email, a.line1 as address1, a.line2 as address2, a.city, a.usps_abbrev as state_code, a.full_state_name, a.zip_code, a.phone
	from ec_items i,
	ec_orders o,
	ec_products p,
	dotlrn_users u
	left join (select *
		   from ec_addresses
		   where address_id in (select max(address_id)
					from ec_addresses
					group by user_id)) a
	on (u.user_id = a.user_id)
	where i.order_id = o.order_id
	and i.product_id = p.product_id
	and o.user_id = u.user_id
	and o.order_state in ('authorized', 'fulfilled', 'returned')
	and i.product_id in (select product_id
			     from ec_category_product_map
			     where category_id = (select attr_value
			  		    	  from apm_parameter_values
			  		    	  where parameter_id = (select parameter_id
			      					  	from apm_parameters
			      					  	where package_key = 'dotlrn-ecommerce'
			      					  	and parameter_name = 'MembershipECCategoryId')))
);