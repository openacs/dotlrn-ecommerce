<master>
  <property name="title">Pending Applications</property>
  <property name="context">{Pending Applications}</property>

  <if @admin_p@>
    <if @type@ eq "pending">
      <a href="applications?type=requests">View User Requests</a>
      <h3>#dotlrn-ecommerce.lt_Users_in_waiting_list#</h3>		
      <p />
      <listtemplate name="applications"></listtemplate>
      <p />
      <h3>#dotlrn-ecommerce.lt_Approved_Users_from_W#</h3>
      <p />
      <listtemplate name="approved_applications"></listtemplate>
    </if>
    <else>
      <a href="applications?type=pending">View Pending</a>
      <h3>#dotlrn-ecommerce.lt_User_requests_for_app#</h3>		
      <p />
      <listtemplate name="for_approval"></listtemplate>
      <p />
      <h3>#dotlrn-ecommerce.lt_Approved_Applications#</h3>
      <p />
      <listtemplate name="approved_applications_prereq"></listtemplate>
    </else>
  </if>
  <else>
    <h3>#dotlrn-ecommerce.lt_User_requests_for_app#</h3>
    <p />
    <listtemplate name="for_approval"></listtemplate>
    <p />
      <h3>#dotlrn-ecommerce.lt_Approved_Applications#</h3>
      <p />
      <listtemplate name="approved_applications_prereq"></listtemplate>
  </else>
