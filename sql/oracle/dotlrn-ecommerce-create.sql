--- creating table to add section

create table dotlrn_ecommerce_section (
	section_id      integer primary key,
	course_id 	integer references cr_items(item_id),
	community_id    integer references dotlrn_communities_all(community_id),
	product_id	integer references  ec_products,
	section_name	varchar(2000),
	age		varchar(2000),
	date_time_start date,  	   
	date_time_end	date,
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
	description	 text
);

create index de_community_id_idx ON dotlrn_ecommerce_section (community_id);
create index de_product_id_idx ON dotlrn_ecommerce_section (product_id);
create index de_course_id_idx ON dotlrn_ecommerce_section (course_id);

-- Term - comes from site-wide categories
-- instructors - come from from instructors group
-- asssistants - come from assistants group
-- actual dates - comes from the calendar items in the community
declare
begin
	acs_rel_type.create_role('as_session_role', 'Assessment Sessions Role', 'Assessment Sessions Role');
	acs_rel_type.create_role('ec_product_role', 'Ecommerce Product Role', 'Ecommerce Product Role');
	acs_rel_type.create_role('member_rel_role', 'Member Relationship Role', 'Member Relationship Role');
	commit;
end;
/
show errors

create table person_info (
	person_id 	integer not null,
	grade		clob,
	allergies 	clob,
	age		integer,
	special_needs	clob,
	CONSTRAINT dotlrn_ecommerce_persons_fk 
	  FOREIGN KEY (person_id)
	  REFERENCES persons(person_id)
);

create table dotlrn_ecommerce_orders (
	item_id		integer references ec_items on delete cascade not null,
-- Can be a user or group
	patron_id	integer	references users(user_id) on delete cascade not null,
	participant_id	integer	references parties(party_id) on delete cascade not null
);

create table dotlrn_ecommerce_transactions (
	order_id	 integer references ec_orders on delete cascade not null unique,
	method		 char(1) check (method in ('cc', 'internal_account', 'check')) not null,
	internal_account clob
);

-- Create custom ecommerce field
insert into ec_custom_product_fields (field_identifier, field_name, default_value, column_type, last_modified,last_modifying_user, modified_ip_address) values ('maxparticipants', 'Max Participants', '', 'integer', sysdate, '0', '0.0.0.0');
alter table ec_custom_product_field_values add maxparticipants integer;
alter table ec_custom_p_field_values_audit add maxparticipants integer;

@@ dotlrn-ecommerce-memberships-create.sql
@@ dotlrn-ecommerce-admin-portlet-create.sql