<master>
  <property name="title">#dotlrn-ecommerce.lt_Completing_Your_Order#</property>
  <property name="context">@context;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

  <if @display_progress@ true>
    <include src="checkout-progress" step="6">
  </if>

  <blockquote>

    <form method="post" action="finalize-order">
      <input type="hidden" name="user_id" value="@user_id@">
	<if @participant_id@ defined><input type="hidden" name="participant_id" value="@participant_id@"></if>
	<p><b>#dotlrn-ecommerce.Push# <input type="submit" value="Submit"> #dotlrn-ecommerce.lt_to_send_us_your_order#</b>
	</p>

	<include src="/packages/dotlrn-ecommerce/lib/summary-for-customer" user_id="@user_id@" order_id="@order_id@" />

	<p><b>#dotlrn-ecommerce.Push# <input type="submit" value="Submit"> #dotlrn-ecommerce.lt_to_send_us_your_order#</b>
	</p>
    </form>

  </blockquote>
