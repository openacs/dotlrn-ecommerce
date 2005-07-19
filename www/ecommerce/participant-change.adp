<master>
  <property name="title">#dotlrn-ecommerce.lt_Whos_participating_in#</property>

  <if @product_id@ defined>
    <if @member_state@ eq "">
      <a href="@participant_pays_url;noquote@" class="button">#dotlrn-ecommerce.lt_Im_participating_in_t#</a>
    </if>
    <else>
      <if @member_state@ in "waitinglist approved" "request approved">
	<a href="@participant_pays_url;noquote@" class="button">#dotlrn-ecommerce.lt_Continue_Registration_1#</a>
      </if>
      <else>
	<if @member_state@ eq "approved">
	  #dotlrn-ecommerce.lt_Youve_already_purchas#
	</if>
	<else>
	  <if @member_state@ in "request approval" "needs approval" "awaiting payment">
	    #dotlrn-ecommerce.lt_Your_request_has_been#
	  </if>
	</else>
      </else>
    </else>
    <if @relations:rowcount@ gt 0>
      <p />
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
    </if>
    <p />  
    <h3>#dotlrn-ecommerce.lt_Or_create_an_account_#</h3>
    <p />
  </if>
  
  <include src="/packages/dotlrn-ecommerce/lib/user-new"
    next_url="@next_url;noquote@" self_register_p="0" />
