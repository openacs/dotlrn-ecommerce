<master>
  <property name="title">#dotlrn-ecommerce.The_section_is_full#</property>

  <div class="boxed-user-message">
    <h3>#dotlrn-ecommerce.The_section_is_full#</h3>
    <p />
    <ul>
      <if @admin_p@>
	<li>#dotlrn-ecommerce.lt_You_may_continue_with#</li>
	<li>#dotlrn-ecommerce.lt_Or_put_this_purchase_#</li>
      </if>
      <else>
	<li>#dotlrn-ecommerce.lt_You_may_wish_to_conti#</li>
      </else>
    </ul>
  </div>
  
  <p />
  <if @admin_p@>
    <a href="@shopping_cart_add_url;noquote@" class="button">#dotlrn-ecommerce.Continue#</a> &nbsp;&nbsp;&nbsp;
  </if>
  <a href="@request_url;noquote@" class="button">#dotlrn-ecommerce.lt_Go_on_the_waiting_lis#</a> &nbsp;&nbsp;&nbsp;
  <a href="@cancel_url;noquote@" class="button">#dotlrn-ecommerce.Cancel#</a>
