<master>
  <property name="title">Thank You For Your Order</property>
  <property name="context">@context;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

  <ul>
    <if @admin_p@>
      <li> <a
	  href="../admin/process-purchase-course?user_id=@user_id@">Purchase
	  another Course/Section</a> for the current purchases</li>
      <li> <a
	  href="../admin/process-purchase-all">Select
	another purchaser</a> </li>
      
      <li> <a
	  href="../admin">Return to main course registration administration</a> </li>
    </if>
    <else>
      <li> <a
	  href="../index">Return to course catalog</a> </li>      
    </else>
  </ul>

<blockquote>
  <p><b>The following has beens sent to the purchaser</b></p>
  @order_summary;noquote@
</blockquote>

