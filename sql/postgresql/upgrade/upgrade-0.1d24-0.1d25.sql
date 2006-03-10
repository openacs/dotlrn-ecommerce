-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d24-0.1d25.sql
-- 
-- @author Roel Canicula (roel@solutiongrove.com)
-- @creation-date 2006-03-11
-- @arch-tag: c8c75af9-53d4-47c4-931b-345860a6553f
-- @cvs-id $Id$
--

alter table dotlrn_ecommerce_section add show_price_p char(1);
alter table dotlrn_ecommerce_section alter show_price_p set default 't';