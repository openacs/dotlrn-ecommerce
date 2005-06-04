<master>
  <property name="title">@title@</property>
  <if @context@ defined><property name="context">@context;noquote@</property></if>

  <if @section_id@ defined and @section_id@ not nil>

    <formtemplate id="search"></formtemplate>
    <p />
    <if @search@ not nil>
      <listtemplate name="users"></listtemplate>
    </if>
    
  </if>

  <p />
  <b>Or create an account for the participant</b>
  
  <if @add_url@ defined and @addpatron_url@ defined>
    <include src="/packages/dotlrn-ecommerce/lib/user-new"
      next_url="@next_url;noquote@" self_register_p="0" add_url="@add_url;noquote@"
      addpatron_url="@addpatron_url;noquote@" />
  </if>
  <else>
    <include src="/packages/dotlrn-ecommerce/lib/user-new"
      next_url="@next_url;noquote@" self_register_p="0" />
  </else>