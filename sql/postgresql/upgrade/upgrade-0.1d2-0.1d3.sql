-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d2-0.1d3.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-08-04
-- @arch-tag: 68054edf-5b79-4e7e-a917-ef82cabe092c
-- @cvs-id $Id$
--

-- Invoice payment method
create table dotlrn_ecommerce_transaction_invoice_payments (
	order_id	integer references ec_orders on delete cascade not null,
	method		text check (method in ('cc', 'internal_account', 'check', 'cash', 'invoice', 'scholarship')) not null,
	internal_account text,
	amount		float not null,
	payment_date	timestamp default current_timestamp not null
);