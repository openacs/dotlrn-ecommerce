-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d4-0.1d5.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-08-10
-- @arch-tag: d0ee3250-194e-46c7-ad87-26b7b1801127
-- @cvs-id $Id$
--

alter table dotlrn_ecommerce_transactions drop constraint dotlrn_ecommerce_transactions_method;
alter table dotlrn_ecommerce_transactions add constraint dotlrn_ecommerce_transactions_method check (method in ('cc', 'internal_account', 'check', 'cash', 'invoice', 'scholarship', 'lockbox'));

alter table dotlrn_ecommerce_transaction_invoice_payments drop constraint dotlrn_ecommerce_transaction_invoice_payments_method;
alter table dotlrn_ecommerce_transaction_invoice_payments add constraint dotlrn_ecommerce_transaction_invoice_payments_method check (method in ('cc', 'internal_account', 'check', 'cash', 'invoice', 'scholarship', 'lockbox'));