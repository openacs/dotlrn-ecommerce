<master>
  <property name="title">#dotlrn-ecommerce.Change_Participant#</property>

  <if @item_id@ defined>
    <h3>
      <if @admin_p@>
	#dotlrn-ecommerce.lt_Users_related_to_the_#
      </if>
      <else>
	#dotlrn-ecommerce.Users_related_to_you#
      </else>
    </h3>
    <p />
    <listtemplate name="relations"></listtemplate>
    <p />
    <if @participant_id@ ne @patron_id@>
      <a href="@participant_pays_url;noquote@" class="button">#dotlrn-ecommerce.lt_patron_name_also_pays#</a>
      &nbsp;&nbsp;&nbsp;
    </if>
    <a href="shopping-cart?user_id=@patron_id@" class="button">#dotlrn-ecommerce.lt_Back_to_shopping_cart#</a>
    <p />  
    <h3>#dotlrn-ecommerce.lt_Or_create_an_account_#</h3>
    <p />
  </if>
  
  <include src="/packages/dotlrn-ecommerce/lib/user-new"
    next_url="@next_url;noquote@" self_register_p="0" />

  <if @item_id@ defined>
    <p />
    <a href="shopping-cart?user_id=@patron_id@" class="button">#dotlrn-ecommerce.lt_Back_to_shopping_cart#</a>
  </if>
