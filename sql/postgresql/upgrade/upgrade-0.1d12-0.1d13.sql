-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d11-0.1d12.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-09-01
-- @arch-tag: e5415c17-2f53-4260-944d-8845077301b8
-- @cvs-id $Id$
--

alter table dotlrn_ecommerce_orders add checked_out_by integer;
alter table dotlrn_ecommerce_orders add constraint "$4" foreign key (checked_out_by) references users(user_id) on delete cascade;
