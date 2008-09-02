<master>
  <property name="title">#dotlrn-ecommerce.Order_Summary#</property>
  <property name="context">@context@</property>

  <listfilters name="orders" style="inline-filters"></listfilters>
  <p />
  <listtemplate name="orders"></listtemplate>
  <p />
  <if @user_id@ defined or @section_id@ defined or @type@ defined or @payment_method@ defined or @start@ defined>
    <a href="index" class="button">#dotlrn-ecommerce.Display_All_Orders#</a>
  </if>
