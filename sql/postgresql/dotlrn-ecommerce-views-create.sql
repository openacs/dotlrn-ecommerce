-- 
-- packages/dotlrn-ecommerce/sql/postgresql/dotlrn-ecommerce-views.sql
-- 
-- @author Tracy Adams (teadams@alum.mit.edu)
-- @arch-tag:
-- @cvs-id $Id$
--

--- creating tables to be used for remote queries.
-- denormalize as much as possible to make it easy for them

-- categories

create view dlec_view_categories as (
	select title as category, category_id, parent_id, tree_id from categories, 
	acs_objects where acs_objects.object_id = categories.category_id
);

-- category tree

create view dlec_view_category_trees as (
	select title, tree_id from category_trees, 
	acs_objects where 
	acs_objects.object_id = category_trees.tree_id
);

-- expenses codes

create view dlec_view_expense_codes as (
	select dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_categories, dlec_view_category_trees
	where dlec_view_category_trees.title = 'Expense Codes'
	and dlec_view_categories.tree_id = dlec_view_category_trees.tree_id
);

-- course types

create view dlec_view_course_types as (
	select dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_categories, dlec_view_category_trees
	where dlec_view_category_trees.title = 'dotlrn-course_catalog'
	and dlec_view_categories.tree_id = dlec_view_category_trees.tree_id
);

-- grade

create view dlec_view_grades as (
	select dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_categories, dlec_view_category_trees
	where dlec_view_category_trees.title = 'Grades'
	and dlec_view_categories.tree_id = dlec_view_category_trees.tree_id
);


-- patron relationships

create view dlec_view_patron_relationships as (
	select dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_categories, dlec_view_category_trees
	where dlec_view_category_trees.title = 'Patron Relationships'
	and dlec_view_categories.tree_id = dlec_view_category_trees.tree_id
);


-- terms

create view dlec_view_expense_terms as (
	select dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_categories, dlec_view_category_trees
	where dlec_view_category_trees.title = 'Terms'
	and dlec_view_categories.tree_id = dlec_view_category_trees.tree_id
);

-- zones

create view dlec_view_zones as (
	select dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_categories, dlec_view_category_trees
	where dlec_view_category_trees.title = 'Zones'
	and dlec_view_categories.tree_id = dlec_view_category_trees.tree_id
);

-- scholarships_funds

create view dlec_view_scholarship_funds as (
      select sf.*
      from scholarship_fundi sf,
           cr_items ci
      where
           sf.revision_id = ci.live_revision
);



-- users

create  view dlec_view_users as (
	select acs_objects.*, persons.*, u.username,
	u.last_visit, u.second_to_last_visit, u.n_sessions
	from acs_objects, users u, persons
	where acs_objects.object_id = u.user_id
	and u.user_id = persons.person_id
);


-- courses

create view dlec_view_courses as (
	select * from dotlrn_catalog, cr_items
	where dotlrn_catalog.course_id = cr_items.live_revision
);

create view dlec_view_courses_and_categories as (
	select dlec_view_courses.*, dlec_view_categories.category, dlec_view_categories.category_id
	from dlec_view_courses, dlec_view_categories, category_object_map
	where dlec_view_courses.course_id = category_object_map.object_id
	and dlec_view_categories.category_id = category_object_map.category_id
);

-- sections

create or replace view dlec_view_sections as (
    select c.course_name, c.course_info, s.*, i.*
    from dotlrn_catalogi c, dotlrn_ecommerce_section s, cr_items i
    where c.item_id = s.course_id
    and c.course_id = i.live_revision
);


-- categoreis with sections
create view dlec_view_sections_and_categories as (
	select dlec_view_sections.*, dlec_view_categories.category, 
         dlec_view_categories.category_id  from dlec_view_sections, 
        dlec_view_categories, category_object_map
	where dlec_view_sections.section_id = category_object_map.object_id
	and dlec_view_categories.category_id = category_object_map.category_id
);


-- expenses per course
 
create view dlec_view_course_expenses as (
	select category, (select section_id 
	from dotlrn_ecommerce_section
	where dotlrn_ecommerce_section.community_id =expenses.community_id) as section_id, exp_id, exp_expense, to_char(exp_date,'MM-DD-YYYY') as exp_date, exp_amount, exp_exported, package_id, community_id from expenses, category_object_map, dlec_view_expense_codes
 where expenses.exp_id = category_object_map.object_id
 and dlec_view_expense_codes.category_id = category_object_map.category_id 
);


-- revenue earned

create view dlec_view_orders as (
    select o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id) as price_to_display, o.user_id as purchasing_user_id, u.first_names, u.last_name, count(*) as n_items, person__name(o.user_id), t.method, s.section_id as _section_id, s.section_name, s.course_id, 
    case when t.method = 'invoice' then
    ec_total_price(o.order_id) - ec_order_gift_cert_amount(o.order_id) - 
    (select coalesce(sum(amount), 0)
     from dotlrn_ecommerce_transaction_invoice_payments
     where order_id = o.order_id) + ec_total_refund(o.order_id)
    else 0 end as balance
    from ec_orders o
    join ec_items i using (order_id)
    join dotlrn_ecommerce_transactions t using (order_id)
    join dotlrn_ecommerce_section s on (i.product_id = s.product_id)
    left join cc_users u on (o.user_id=u.user_id)
    group by o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id), o.user_id, u.first_names, u.last_name, o.in_basket_date, t.method, s.section_name, s.section_id, s.course_id, o.authorized_date, balance
);

create view dlec_view_section_report as (
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

create view dlec_view_membership_orders as (
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

-- scholarships allocated
--create view dlec_view_scholarships_allocated as (
--    select person__name(user_id), to_char(grant_date, 'Month dd, yyyy hh:miam') as grant_date, grant_amount, dlec_view_scholarship_funds.fund_id, dlec_view_scholarship_funds.account_code, dlec_view_scholarship_funds.object_title
--    from scholarship_fund_grants, dlec_view_scholarship_funds
--    where scholarship_fund_grants.fund_id = dlec_view_scholarship_funds.fund_id
--    group by person__name, grant_date, grant_amount, account_code, object_title, dotlrn_view_scholarship_funds.fund_id
--    order by scholarship_fund_grants.grant_date
--);


-- instructors
-- assistant instructors
-- registrants (with patrons and participant contact)
-- users and their patrons

-- sessions
-- attendance


