<master>
  <property name="title">Pending Applications</property>
  <property name="context">{Pending Applications}</property>

  <if @admin_p@>
    <h3>#dotlrn-ecommerce.lt_Users_in_waiting_list#</h3>
    <p />
    <listtemplate name="applications"></listtemplate>
    <p />
  </if>
  
  <h3>#dotlrn-ecommerce.lt_User_requests_for_app#</h3>
  <p />
  <listtemplate name="for_approval"></listtemplate>
