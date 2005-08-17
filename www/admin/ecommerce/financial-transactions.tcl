# packages/dotlrn-ecommerce/www/admin/ecommerce/financial-transactions.tcl

ad_page_contract {
    
    Financial transactions page
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-17
    @arch-tag: e3a4648c-6ae1-4a93-ac7f-f1fd97f04d2f
    @cvs-id $Id$
} {
    order_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "Financial Transactions"]