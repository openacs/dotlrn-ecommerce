<master>
  <property name="title">#dotlrn-ecommerce.lt_Bulk_Approve_Applicat#</property>

  <if @applications:rowcount;literal@ gt 0>
    #dotlrn-ecommerce.lt_Approve_the_following#
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
    #dotlrn-ecommerce.lt_The_following_applica#
    <ul>
      <multiple name="todo">
	<li><a href="@todo.url;noquote@">(@todo.type@) @todo.community_name@</a></li>
      </multiple>
      
      <if @filter_community_id@ not nil>
	<br />
	<li><a href="@now_url;noquote@">#dotlrn-ecommerce.lt_Applications_that_can#</a></li>
      </if>
    </ul>
  </if>
  <elseif @filter_community_id@ not nil>
    <ul>
      <li><a href="@now_url;noquote@">#dotlrn-ecommerce.lt_Applications_that_can_1#</a></li>
    </ul>
  </elseif>

  <p />

  <if @approved:rowcount;literal@ gt 0>
    #dotlrn-ecommerce.lt_The_following_applica_1#
    <p />
    <ul>
      <multiple name="approved">
	<li>@approved.community_name@: @approved.person__name@</li>
      </multiple>
    </ul>
  </if>

  <p />

  <a href="@return_url;noquote@" class="button">#dotlrn-ecommerce.Back_to# #dotlrn-ecommerce.lt_Waiting_List_and_Prer#</a>