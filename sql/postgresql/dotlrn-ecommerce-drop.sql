-- 
-- packages/dotlrn-ecommerce/sql/postgresql/dotlrn-ecommerce-drop.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-05-14
-- @arch-tag: 6aff811d-34fc-46ac-bf89-4c26378075bc
-- @cvs-id $Id$
--

drop table dotlrn_ecommerce_transactions;
drop table dotlrn_ecommerce_prereqs;
drop table dotlrn_ecommerce_prereq_map;
drop table dotlrn_ecommerce_section;
drop table person_info;

select acs_rel_type__drop_role('as_session_role');
select acs_rel_type__drop_role('ec_product_role');

\i dotlrn-ecommerce-views-drop.sql