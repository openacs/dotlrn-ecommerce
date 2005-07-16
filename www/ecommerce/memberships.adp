<master>
  <property name="title">@title@</property>
  <property name="context">@context@</property>
  
<if @suppress_membership_p@ ne 1>
  <include src="/packages/dotlrn-ecommerce/lib/categorized-products" category_id="@category_id@" user_id="@user_id@" restrict_to_one_p="1" />
</if>
