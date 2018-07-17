<master>
  <property name="title">#dotlrn-ecommerce.lt_Bulk_Reject_Applicati#</property>

  <if @applications:rowcount;literal@ gt 0>
    #dotlrn-ecommerce.lt_Reject_the_following_#
    <p />
    <ul>
      <multiple name="applications">
	<li>(@applications.type@) @applications.community_name@: @applications.person__name@</li>
      </multiple>
    </ul>
  
    <formtemplate id="confirm"></formtemplate>
  </if>

  <p />

  <if @todo:rowcount;literal@ gt 0>
    #dotlrn-ecommerce.lt_The_following_applica_2#
    <ul>
      <multiple name="todo">
	<li><a href="@todo.url;noquote@">(@todo.type@) @todo.community_name@</a></li>
      </multiple>
    </ul>
  </if>
  <else>
    #dotlrn-ecommerce.lt_The_applications_have#
  </else>

  <p />


  <a href="@return_url;noquote@" class="button">#dotlrn-ecommerce.Back_to# #dotlrn-ecommerce.lt_Waiting_List_and_Prer#</a>