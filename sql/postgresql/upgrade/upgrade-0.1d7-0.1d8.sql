-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d7-0.1d8.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-08-21
-- @arch-tag: 113155d4-1dc1-47f2-988b-63f190fc8087
-- @cvs-id $Id$
--

insert into ec_custom_product_fields (field_identifier, field_name, default_value, column_type, last_modified,last_modifying_user, modified_ip_address) values ('show_description_p', 'Show Section Description', '', 'boolean', now(), '0', '0.0.0.0');
alter table ec_custom_product_field_values add show_description_p boolean;
alter table ec_custom_p_field_values_audit add show_description_p boolean;