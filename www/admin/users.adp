<master>
  <property name="title">#dotlrn-ecommerce.List_Users#</property>
  <property name="context">{#dotlrn-ecommerce.List_Users#}</property>

    <formtemplate id="search"></formtemplate>
    <p />
    <if @search@ not nil>
      <listtemplate name="users"></listtemplate>
    </if>