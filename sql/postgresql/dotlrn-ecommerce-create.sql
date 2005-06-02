-- 
-- packages/dotlrn-ecommerce/sql/postgresql/dotlrn-ecommerce-create.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-05-14
-- @arch-tag: 8371aa52-3001-45da-9391-e181130bbedf
-- @cvs-id $Id$
--

--- creating table to add section

create table dotlrn_ecommerce_section (
	section_id      integer primary key,
	course_id 	integer references cr_items(item_id),
	community_id    integer references dotlrn_communities_all(community_id),
	product_id	integer references  ec_products,
	section_name	varchar(2000),
	age		varchar(2000),
	date_time_start timestamptz,  	   
	date_time_end	timestamptz,
	daily_p		char(1) check (daily_p in ('t','f')),
	weekly_p        char(1) check (weekly_p in ('t','f')),	
	qualified_age_low   integer,
	qualified_age_high  integer,
	account_code_revenue varchar(100),
	account_code_expense varchar(100),
	max_participants     integer,
	waiting_list_p       char(1) check (daily_p in ('t','f')),
	notify_waiting_number integer,
	member_price_number   numeric,
	non_member_price      numeric
);

create index dotlrn_ecommerce_community_id_idx ON dotlrn_ecommerce_section (community_id);
create index dotlrn_ecommerce_product_id_idx ON dotlrn_ecommerce_section (product_id);
create index dotlrn_ecommerce_course_id_idx ON dotlrn_ecommerce_section (course_id);

-- Term - comes from site-wide categories
-- instructors - come from from instructors group
-- asssistants - come from assistants group
-- actual dates - comes from the calendar items in the community

select acs_rel_type__create_role('as_session_role', 'Assessment Sessions Role', 'Assessment Sessions Role');
select acs_rel_type__create_role('ec_product_role', 'Ecommerce Product Role', 'Ecommerce Product Role');

create table person_info (
	person_id 	integer references persons not null,
	grade		text,
	allergies 	text,
	age		integer
);

\i dotlrn-ecommerce-memberships-create.sql