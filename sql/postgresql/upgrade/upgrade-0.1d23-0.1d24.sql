-- adding credit card type to dlec_view_orders

drop view dlec_view_orders cascade;

create or replace view dlec_view_orders as (
    select o.order_id, to_char(o.confirmed_date, 'Mon dd, yyyy hh:miam') 
	as confirmed_date, to_char(o.confirmed_date, 'Mon dd, yyyy') as confirmed_date_only_date, o.order_state,   (i.price_charged + 
	coalesce(i.shipping_charged, 0) + coalesce(i.price_tax_charged, 0)
     	- coalesce(i.price_refunded, 0) - coalesce(i.shipping_refunded, 0) 
	- coalesce(i.price_tax_refunded, 0)) as price_to_display,
	o.user_id as purchasing_user_id, u.first_names, u.last_name, 
	t.method, coalesce((select true
		where exists (select *
			from ec_gift_certificate_usage
			where order_id = o.order_id
			and exists (select *
				from scholarship_fund_grants
				where ec_gift_certificate_usage.gift_certificate_id 				      = gift_certificate_id))), false) as has_scholarship_p,
				s.section_id as _section_id, 
		    	coalesce((select course_name
	      		from dlec_view_sections
	      		where section_id = s.section_id)||': '||s.section_name, 
			p.product_name) as _section_name, s.course_id,
        case when t.method = 'cc' then
	(select creditcard_type from ec_creditcards where 
	ec_creditcards.creditcard_id = o.creditcard_id)
	else null end as credit_card_type,	 
	case when t.method = 'invoice' then
   	ec_total_price(o.order_id) - ec_order_gift_cert_amount(o.order_id) - 
    	(select coalesce(sum(amount), 0)
     	from dotlrn_ecommerce_transaction_invoice_payments
     	where order_id = o.order_id) + ec_total_refund(o.order_id)
    	else 0 end as balance, 
	(coalesce(i.price_refunded, 0) + coalesce(i.shipping_refunded, 0) - 
	coalesce(i.price_tax_refunded, 0)) as refund_price,
	(i.price_charged + coalesce(i.shipping_charged, 0) + 
	coalesce(i.price_tax_charged, 0)) as total_price, 
    (select to_char(refund_date, 'Mon dd, yyyy')
     from ec_refunds
     where order_id = o.order_id
     order by refund_date desc
     limit 1) as refund_date, 
     u.first_names||' '||u.last_name as purchaser,
     i.item_id, deo.participant_id, case when ao.object_type = 'group' then acs_group__name(deo.participant_id) else person__name(deo.participant_id) end as participant_name,
    deo.checked_out_by, u.user_id as purchaser_id, (deo.checked_out_by != u.user_id) 
	as checked_out_by_admin_p, o.authorized_date, o.confirmed_date as confirmed_date_date_column, ao.object_type
    from ec_orders o
    join ec_items i using (order_id)
    join ec_products p using (product_id)
    join dotlrn_ecommerce_orders deo using (item_id)
    join acs_objects ao on (deo.participant_id = ao.object_id)
    join dotlrn_ecommerce_transactions t using (order_id)
    left join dotlrn_ecommerce_section s on (i.product_id = s.product_id)
    left join cc_users u on (o.user_id=u.user_id)
    where o.order_state in ('confirmed', 'authorized', 'fulfilled', 'returned'));

-- Change membership states to more appropriate names
alter table membership_rels drop constraint membership_rel_mem_ck;
update membership_rels set member_state = 'application sent' where member_state = 'application sent';
update membership_rels set member_state = 'application approved' where member_state = 'application approved';
alter table membership_rels add constraint membership_rel_mem_ck check (member_state::text = 'merged'::text OR member_state::text = 'approved'::text OR member_state::text = 'needs approval'::text OR member_state::text = 'banned'::text OR member_state::text = 'rejected'::text OR member_state::text = 'deleted'::text OR member_state::text = 'request approval'::text OR member_state::text = 'request approved'::text OR member_state::text = 'waitinglist approved'::text or member_state::text = 'application sent' or member_state::text = 'application approved');