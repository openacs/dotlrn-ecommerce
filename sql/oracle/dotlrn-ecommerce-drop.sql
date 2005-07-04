drop table dotlrn_ecommerce_section;
drop table person_info;

begin
	acs_rel_type.drop_role('as_session_role');
	acs_rel_type.drop_role('ec_product_role');
	commit;
end;