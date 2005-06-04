<master>
  <property name="title">Completing Your Order: Verify and submit order</property>
  <property name="context_bar">@context_bar;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

<if @display_progress@ true>
  <include src="checkout-progress" step="6">
</if>

<blockquote>

  <form method="post" action="finalize-order">
      <input type="hidden" name="user_id" value="@user_id@">
	<if @participant_id@ defined><input type="hidden" name="participant_id" value="@participant_id@"></if>
    <p><b>Push <input type="submit" value="Submit"> to send us your order!</b>
    </p>

    @order_summary;noquote@

    <p><b>Push <input type="submit" value="Submit"> to send us your order!</b>
    </p>
  </form>

</blockquote>
