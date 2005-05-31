-- 
-- packages/dotlrn-ecommerce/sql/postgresql/dotlrn-ecommerce-drop.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-05-14
-- @arch-tag: 6aff811d-34fc-46ac-bf89-4c26378075bc
-- @cvs-id $Id$
--

drop table dotlrn_ecommerce_section;

select acs_rel_type__drop_role('as_session_role');
select acs_rel_type__drop_role('ec_product_role');