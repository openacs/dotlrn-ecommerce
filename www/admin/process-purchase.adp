<master>
  <property name="title">Process Purchase</property>
  <property name="context">@context;noquote@</property>

  <if @section_id@ defined and @section_id@ not nil>

    <formtemplate id="search"></formtemplate>
    <p />
    <if @search@ not nil>
      <listtemplate name="users"></listtemplate>
    </if>
    
  </if>

  <p />
  <b>Or create an account for the participant</b>
  
  <include src="/packages/acs-subsite/lib/user-new"
    next_url="@next_url;noquote@" self_register_p="0"/>
  
  <if @section_id@ defined and @section_id@ not nil>
    <if @members:rowcount@ gt 0>
      <p />
      <h3>Members</h3>
      <p />
      <listtemplate name="members"></listtemplate>
    </if>
  </if>