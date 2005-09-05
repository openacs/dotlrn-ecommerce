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
    <h3>#dotlrn-ecommerce.lt_Thank_you_for_your_ap#</h3>
</else>

  </div>
  
  <p />
<!--
  <a href="home" class="button">#dotlrn-ecommerce.Go_to_My_Account#</a> &nbsp;&nbsp;&nbsp;
-->
  <a href="index" class="button">#dotlrn-ecommerce.lt_Register_for_Another_#</a>
