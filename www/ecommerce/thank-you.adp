<master>
  <property name="title">#dotlrn-ecommerce.lt_Thank_You_For_Your_Or#</property>
  <property name="context">@context;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

  <ul>
    <if @admin_p@>
      <li> <a
	  href="../admin/process-purchase-course?user_id=@user_id@">#dotlrn-ecommerce.lt_Purchase_another_Cour#</a> #dotlrn-ecommerce.lt_for_the_current_purch#</li>
      <li> <a
	  href="../admin/process-purchase-all">#dotlrn-ecommerce.lt_Select_another_purcha#</a> </li>
      
      <li> <a
	  href="../admin">#dotlrn-ecommerce.lt_Return_to_main_course#</a> </li>
    </if>
    <else>
      <li> <a
	  href="../index">#dotlrn-ecommerce.lt_Return_to_course_cata#</a> </li>      
    </else>
  </ul>

<blockquote>
  <p><b>#dotlrn-ecommerce.lt_The_following_has_bee#</b></p>
    <include src="/packages/dotlrn-ecommerce/lib/summary-for-customer" user_id="@user_id@" order_id="@order_id@" />
</blockquote>
