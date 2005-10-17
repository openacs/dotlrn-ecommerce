-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d22-0.1d23.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-10-17
-- @arch-tag: eed5abe5-d150-48cc-bcc9-c6d3197cd0ce
-- @cvs-id $Id$
--

insert into ec_custom_product_fields (field_identifier, field_name, default_value, column_type, last_modified,last_modifying_user, modified_ip_address) values ('display_section_p', 'Display Section', '', 'boolean', now(), '0', '0.0.0.0');
alter table ec_custom_product_field_values add display_section_p boolean;
alter table ec_custom_p_field_values_audit add display_section_p boolean;

update ec_custom_product_field_values set display_section_p = 't';