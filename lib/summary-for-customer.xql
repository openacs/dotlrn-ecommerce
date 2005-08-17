<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/dotlrn-ecommerce/lib/summary-for-customer.xql -->
<!-- @author  (mgh@localhost.localdomain) -->
<!-- @creation-date 2005-07-06 -->
<!-- @arch-tag: 6b485822-def0-401f-ae65-8edf1525bcf6 -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name="correct_user_id">      
    <querytext>
      select user_id as correct_user_id
      from ec_orders 
      where order_id = :order_id
    </querytext>
  </fullquery>

  <fullquery name="order_info_select">      
    <querytext>
      select o.confirmed_date, o.creditcard_id, o.shipping_method,
      u.email, o.shipping_address as shipping_address_id, c.billing_address as billing_address_id
      from ec_orders o
      left join cc_users u on (o.user_id = u.user_id)
      left join ec_creditcards c on (o.creditcard_id = c.creditcard_id)
      where o.order_id = :order_id
    </querytext>
  </fullquery>

  <fullquery name="order_details_select">      
    <querytext>
      select i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice, p.product_name, p.one_line_description, p.product_id, count(*) as quantity, coalesce(s.course_name||': '||s.section_name, p.product_name) as section_name
      from ec_items i, ec_products p
	left join dlec_view_sections s
	on (p.product_id = s.product_id)

      where i.order_id = :order_id
      and i.product_id = p.product_id
      group by p.product_name, p.one_line_description, p.product_id, i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice, s.course_name, s.section_name
    </querytext>
  </fullquery>  
</queryset>
