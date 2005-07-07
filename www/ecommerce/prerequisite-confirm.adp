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
  <a href="@shopping_cart_add_url;noquote@" class="button">Continue</a> &nbsp;&nbsp;&nbsp;
  <if @admin_p@ ne 1>
    <a href="" class="button">Hold slot and wait for confirmation</a> &nbsp;&nbsp;&nbsp;
  </if>
  <a href="@return_url;noquote@" class="button">Cancel</a>
