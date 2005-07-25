<master>
  <property name="title">#dotlrn-ecommerce.lt_Section_Prerequisites#</property>

  <div class="boxed-user-message">
    <h3>#dotlrn-ecommerce.lt_One_or_more_prerequis#</h3>
    <p />
    <ul>
      <multiple name="prereqs">
	<li>#dotlrn-ecommerce.lt_Required_prereqsfield#</li>
      </multiple>
    </ul>
  </div>
  
  <p />
  <if @admin_p@ eq 1>
  <a href="@shopping_cart_add_url;noquote@" class="button">#dotlrn-ecommerce.Continue#</a> &nbsp;&nbsp;&nbsp;
  </if>
  <a href="@request_url;noquote@" class="button">#dotlrn-ecommerce.lt_Hold_slot_and_wait_fo#</a> &nbsp;&nbsp;&nbsp;
  <a href="@cancel_url;noquote@" class="button">#dotlrn-ecommerce.Cancel#</a>
