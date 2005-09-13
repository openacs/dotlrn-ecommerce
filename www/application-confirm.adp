<master>
<if @member_state@ eq "request approval">
  <property name="title">Application Confirmed</property>	
</if>
<else>
  <property name="title">#dotlrn-ecommerce.lt_Application_Confirmed#</property>
</else>

  <div class="boxed-user-message">

<if @member_state@ eq "request approval">
    <h3>Thank you for applying for a prerequisite exception for @section_name@.  We will notify you if a space becomes available.
</h3>
</if>
<else>
    <h3>@message;noquote@</h3>
</else>

  </div>
  
  <p />
<!--
  <a href="home" class="button">#dotlrn-ecommerce.Go_to_My_Account#</a> &nbsp;&nbsp;&nbsp;
-->

<if @admin_p@>
    <ul>
      <li> <a
	  href="admin/process-purchase-course?user_id=@patron_id@">#dotlrn-ecommerce.lt_Purchase_another_Cour#</a> #dotlrn-ecommerce.lt_for_the_current_purch#</li>
      <li> <a
	  href="admin/process-purchase-all">#dotlrn-ecommerce.lt_Select_another_purcha#</a> </li>
      
      <li> <a
	  href="admin">#dotlrn-ecommerce.lt_Return_to_main_course#</a> </li>
    </ul>

</if>
<else>
  <a href="index" class="button">#dotlrn-ecommerce.lt_Register_for_Another_#</a>
</else>