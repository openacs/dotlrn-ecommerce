<?xml version="1.0"?>

<queryset>

  <fullquery name="get_order_id">      
    <querytext>
      select order_id 
      from ec_orders 
      where user_session_id=:user_session_id 
      and order_state='in_basket'
    </querytext>
  </fullquery>

  <fullquery name="delete_item_from_cart">      
    <querytext>
      delete from ec_items
      where order_id=:order_id 
      and product_id=:product_id
      and color_choice [ec_decode $color_choice "" "is null" "= :color_choice"] 
      and size_choice [ec_decode $size_choice "" "is null" "= :size_choice"] 
      and style_choice [ec_decode $style_choice "" "is null" "= :style_choice"]

      $process_purchase_clause
    </querytext>
  </fullquery>

  <partialquery name="delete_item_from_cart_purchase_process">
    <querytext>
      and item_id in (select item_id
      from dotlrn_ecommerce_orders
      where order_id = :order_id
      and product_id = :product_id
      and patron_id = :patron_id
      and participant_id = :participant_id)
    </querytext>
  </partialquery>

  <partialquery name="delete_item_from_cart_purchase_process_group">
    <querytext>
      and item_id = (select max(item_id)
      from dotlrn_ecommerce_orders
      where order_id = :order_id
      and product_id = :product_id
      and patron_id = :patron_id
      and participant_id = :participant_id)
    </querytext>
  </partialquery>
</queryset>
