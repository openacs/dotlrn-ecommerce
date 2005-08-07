<master>
  <property name="title">#dotlrn-ecommerce.The_section_is_full#</property>

  <div class="boxed-user-message">
    <h3>#dotlrn-ecommerce.The_section_is_full#</h3>
    <p />
    <ul>
      <if @admin_p@>
	<li>#dotlrn-ecommerce.lt_You_may_continue_with# <a href="@shopping_cart_add_url;noquote@" class="button">#dotlrn-ecommerce.Continue#</a></li>
	<li>#dotlrn-ecommerce.lt_Or_put_this_purchase_# <a href="@request_url;noquote@" class="button">#dotlrn-ecommerce.lt_Go_on_the_waiting_lis#</a></li>
      </if>
      <else>
	<li>#dotlrn-ecommerce.lt_You_may_wish_to_conti# <a href="@request_url;noquote@" class="button">#dotlrn-ecommerce.lt_Go_on_the_waiting_lis#</a></li>
      </else>
	<li>#dotlrn-ecommerce.lt_You_may_wish_to_regis# <a href="@cancel_url;noquote@" class="button">#dotlrn-ecommerce.lt_Course_listing#</a></li>
    </ul>
  </div>
  
  <p />
