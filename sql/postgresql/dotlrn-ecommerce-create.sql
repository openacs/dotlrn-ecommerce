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
	waiting_list_p       char(1) check (waiting_list_p in ('t','f')),
	notify_waiting_number integer,
	member_price_number   numeric,
	non_member_price      numeric,
	show_participants_p   char(1) check (show_participants_p in ('t','f'))
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
select acs_rel_type__create_role('member_rel_role', 'Member Relationship Role', 'Member Relationship Role');

create table person_info (
	person_id 	integer references persons not null,
	grade		text,
	allergies 	text,
	age		integer,
	special_needs	text
);

create table dotlrn_ecommerce_orders (
	item_id		integer references ec_items on delete cascade not null,
-- Can be a user or group
	patron_id	integer	references users(user_id) on delete cascade not null,
	participant_id	integer	references parties(party_id) on delete cascade not null
);

create table dotlrn_ecommerce_transactions (
	order_id	 integer references ec_orders on delete cascade not null unique,
	method		 text check (method in ('cc', 'internal_account', 'check')) not null,
	internal_account text
);

-- user_field should point to person_info fields
-- maybe the person_info fields should be object attributes
create table dotlrn_ecommerce_prereq_map (
	tree_id		integer references category_trees on delete cascade not null,
	user_field	text
);

create table dotlrn_ecommerce_prereqs (
	section_id	integer references dotlrn_ecommerce_section on delete cascade not null,
	tree_id		integer references category_trees on delete cascade not null
);

-- Create custom ecommerce field
insert into ec_custom_product_fields (field_identifier, field_name, default_value, column_type, last_modified,last_modifying_user, modified_ip_address) values ('maxparticipants', 'Max Participants', '', 'integer', now(), '0', '0.0.0.0');
alter table ec_custom_product_field_values add maxparticipants integer;
alter table ec_custom_p_field_values_audit add maxparticipants integer;

-- Add member states
alter table membership_rels drop constraint membership_rel_mem_ck;
alter table membership_rels add CONSTRAINT membership_rel_mem_ck CHECK ((((((((member_state)::text = 'merged'::text) OR ((member_state)::text = 'approved'::text)) OR ((member_state)::text = 'needs approval'::text)) OR ((member_state)::text = 'banned'::text)) OR ((member_state)::text = 'rejected'::text)) OR ((member_state)::text = 'deleted'::text) OR ((member_state)::text = 'request approval'::text) OR ((member_state)::text = 'request approved'::text) OR ((member_state)::text = 'waitinglist approved'::text) OR ((member_state)::text = 'awaiting payment'::text) OR ((member_state)::text = 'payment received'::text)));

\i dotlrn-ecommerce-memberships-create.sql
\i dotlrn-ecommerce-admin-portlet-create.sql
