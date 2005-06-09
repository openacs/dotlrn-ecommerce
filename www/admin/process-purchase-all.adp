<master>
  <property name="title">@title@</property>
  <if @context@ defined><property name="context">@context;noquote@</property></if>

    <formtemplate id="search"></formtemplate>
    <p />
    <if @search@ not nil>
      <listtemplate name="users"></listtemplate>
    </if>
    
  <p />
  <b>Or create an account for the purchaser</b>
  
  <include src="/packages/acs-subsite/lib/user-new"
    next_url="@next_url;noquote@" self_register_p="0"/>
