<master>
  <property name="title">#acs-subsite.Log_In#</property>
  <property name="context">{#acs-subsite.Log_In#}</property>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>
  
  <h3>#dotlrn-ecommerce.lt_Registering_for_class#</h3>
  <p />

  <include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">

