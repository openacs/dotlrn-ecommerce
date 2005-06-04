<?xml version="1.0"?>

<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.1</version>
  </rdbms>

  <fullquery name="insert_new_ec_order">      
    <querytext>
      insert into ec_orders
      (order_id, user_session_id, order_state, in_basket_date)
      select :order_id, :user_session_id, 'in_basket', current_timestamp 
      where not exists (select 1 from ec_orders where user_session_id=:user_session_id and order_state='in_basket')
    </querytext>
  </fullquery>

  <fullquery name="insert_problem_into_log">      
    <querytext>
      insert into ec_problems_log
      (problem_id, problem_date, problem_details)
      values
      (ec_problem_id_sequence.nextval, current_timestamp,:errormsg)
    </querytext>
  </fullquery>

  <fullquery name="insert_new_item_in_order">      
    <querytext>
    insert into ec_items
    (item_id, product_id, color_choice, size_choice, style_choice, order_id, in_cart_date)
    select ec_item_id_sequence.nextval, :product_id, :color_choice,
    :size_choice, :style_choice, :order_id, current_timestamp from dual
    </querytext>
  </fullquery>

</queryset>
