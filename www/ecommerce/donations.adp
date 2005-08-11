<master>
  <property name="title">@title@</property>
  <property name="context">@context@</property>
  
<if @donation_category_id@ not nil>
  <include src="/packages/dotlrn-ecommerce/lib/categorized-products" category_id="@donation_category_id@" user_id="@user_id@" />
</if>
