-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d1-0.1d2.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-07-31
-- @arch-tag: 07ad1a3f-f53c-4f51-ae9a-cab8f9e69642
-- @cvs-id $Id$
--

-- Add payment methods
alter table dotlrn_ecommerce_transactions drop constraint dotlrn_ecommerce_transactions_method;
alter table dotlrn_ecommerce_transactions add constraint dotlrn_ecommerce_transactions_method check (method in ('cc', 'internal_account', 'check', 'cash', 'invoice', 'scholarship'));