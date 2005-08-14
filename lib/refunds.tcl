# packages/dotlrn-ecommerce/lib/refunds.tcl
#
# Refunds
#
# @author Roel Canicula (roelmc@pldtdsl.net)
# @creation-date 2005-08-14
# @arch-tag: a2801cc7-9b21-4cf9-80b2-66d9f2a42425
# @cvs-id $Id$

foreach required_param {order_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

db_multirow refunds refunds_select {
    select r.refund_id, r.refund_date, r.refunded_by, r.refund_reasons, r.refund_amount, u.first_names, u.last_name, p.product_name, p.product_id, i.price_name, i.price_charged, count(*) as quantity
    from ec_refunds r, cc_users u, ec_items i, ec_products p
    where r.order_id=:order_id
    and r.refunded_by=u.user_id
    and i.refund_id=r.refund_id
    and p.product_id=i.product_id
    group by r.refund_id, r.refund_date, r.refunded_by, r.refund_reasons, r.refund_amount, u.first_names, u.last_name, p.product_name, p.product_id, i.price_name, i.price_charged
} {
    set refund_date [ec_formatted_full_date $refund_date]
    set refund_amount [ec_pretty_price $refund_amount]
}