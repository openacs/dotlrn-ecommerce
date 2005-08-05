<master>

  <listtemplate name="scholarships"></listtemplate>

  <div class="boxed-user-message">
    <p />
    <if @total_amount@ eq 0>
      <h3>You have not granted any scholarship amount</h3>
    </if>
    <else>
      <if @amountsub@ lt 0>
	<h3>The scholarship granted does not cover the order amount of @pretty_total_price@.</h3>
      </if>
      <if @amountsub@ ge 0 and @amountsub@ lt 0.01>
	<h3>The scholarship covers the order amount of @pretty_total_price@.</h3>
      </if>
    </else>
    <if @amountsub@ gt 0>
      <h3>
	The scholarship granted exceeds the order amount of @pretty_total_price@.<br />
	The balance can be used by the user in future purchases.
      </h3>
    </if>
  </div>

  <p />
  <a href="@back_url;noquote@" class="button">Back</a>
  <if @total_amount@ lt @order_total_price_pre_gift_certificate@>
    <a href="@next_url;noquote@" class="button">Continue Purchase via Other Method</a>
  </if>
  <else>
    <a href="@next_url;noquote@" class="button">Continue Checkout</a>
  </else>
