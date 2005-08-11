# packages/dotlrn-ecommerce/www/order.tcl

ad_page_contract {
    
    Order page for user
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-11
    @arch-tag: 4c786d3b-89eb-4f45-919f-bdd3c27f014a
    @cvs-id $Id$
} {
    user_id:integer,notnull
    order_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

