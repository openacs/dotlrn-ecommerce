<master>
  <property name=title>@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">user_info.first_names</property>
  <property name="displayed_object_id">@user_id@</property>

  <table width=100% cellpadding=0 cellspacing=0>
    <tr>
      <td width=50% valign=top>

	<h2>#acs-subsite.Basic_Information#</h2>

	<include src="/packages/dotlrn-ecommerce/lib/user-info" cancel="@cancel@" add_url="home" return_url="home" />
	<if @edit_reg_url@ defined>
	<p />
	  <ul class="action-links">
	    <li>#dotlrn-ecommerce.lt_Registration_assessme# [<a href="@edit_reg_url;noquote@">#acs-kernel.common_Edit#</a>]</li>
	  </ul>
	</if>

	<p><a href="@community_member_url@">#acs-subsite.lt_What_other_people_see#</a></p>

	<list name="fragments">
	  @fragments:item;noquote@
	</list>

	<if @account_status@ eq "closed">
	  #acs-subsite.Account_closed_workspace_msg#
	</if>

	<h2>#acs-kernel.common_Actions#</h2>
	<ul class="action-links">
	  <li><a href="../user/email-privacy-level">#acs-subsite.Change_my_email_P#</a></li>
	  <li><a href="../user/password-update">#acs-subsite.Change_my_Password#</a></li>

	  <if @change_locale_url@ not nil>
	    <li><a href="@change_locale_url@">#acs-subsite.Change_locale_label#</a></li>
	  </if>

	  <if @notifications_url@ not nil>
	    <li><a href="@notifications_url@">#acs-subsite.Manage_your_notifications#</a></li>
	  </if>

	  <if @account_status@ ne "closed">
	    <li><a href="unsubscribe">#acs-subsite.Close_your_account#</a></li>
	  </if>

	  <li><a href="@catalog_url;noquote@">#dotlrn-ecommerce.lt_Register_for_another_#</a></li>
	</ul>

	<if @portrait_state@ eq upload>
	  <h2>#acs-subsite.Your_Portrait#</h2>
	  <p>
	    #acs-subsite.lt_Show_everyone_else_at#  <a href="@portrait_upload_url@">#acs-subsite.upload_a_portrait#</a>
	  </p>
	</if>

	<if @portrait_state@ eq show>
	  <h2>#acs-subsite.Your_Portrait#</h2>
	  <p>
	    #acs-subsite.lt_On_portrait_publish_d#.
	  </p>
	</if>

	<h2>#acs-subsite.Whos_Online_title#</h2>
	<ul class="action-links">
	  <li><a href="@whos_online_url@">#acs-subsite.Whos_Online_link_label#</a></li>
	</ul>

	<if @invisible_p;literal@ true>
	  #acs-subsite.Currently_invisible_msg#
	  <ul class="action-links">
	    <li><a href="@make_visible_url@">#acs-subsite.Make_yourself_visible_label#</a></li>
	  </ul>
	</if>
	<else>
	  #acs-subsite.Currently_visible_msg#
	  <ul class="action-links">
	    <li><a href="@make_invisible_url@">#acs-subsite.Make_yourself_invisible_label#</a></li>
	  </ul>
	</else>

      </td>
      <td width=50% valign=top>

	<h2>#dotlrn-ecommerce.Your_Order_History#</h2>
	<ul class="action-links">
	  <if @orders:rowcount;literal@ gt 0>
	    <multiple name="orders">
	      <li><a href="@orders.order_url;noquote@">@orders.order_id@</a>; @orders.confirmed_date@</li>
	    </multiple>
	  </if>
	  <else>
	    <li>#dotlrn-ecommerce.You_have_no_orders#</li>
	  </else>
	</ul>
	<if @applications_p;literal@ true>
	  <h2>#dotlrn-ecommerce.Your_Applications#</h2>
	</if>
	<else>
	  <h2>#dotlrn-ecommerce.Your_Prereq_Waiver_Requests#</h2>
	</else>
	<ul class="action-links">
	  <if @sessions_with_applications@ gt 0>

	    <multiple name="sessions">
	      
	      <if @admin_p;literal@ true>
		<li> <a href="@sessions.asm_url;noquote@">@sessions.pretty_name@</a> <if @user_id@ ne @sessions.participant_id@>(@sessions.name@)</if>
	      </if>
	      <else>
		<li> @sessions.pretty_name@ <if @user_id@ ne @sessions.participant_id@>(@sessions.name@)</if>
	      </else>    
	      <if @sessions.member_state@ eq "request approved">
		
		- Request approved <br/>
		<a href="@sessions.register_url@" class="button">#dotlrn-ecommerce.lt_Continue_Registration#</a>
	      </if>
	      

	      <if @use_embedded_application_view_p@ ne 1> 
		[<a href="@sessions.edit_asm_url;noquote@">#acs-kernel.common_Edit#</a>] [<a onclick="return confirm('Are you sure you want to cancel your application?')" href="@sessions.cancel_url;noquote@">#dotlrn-ecommerce.lt_Cancel_your_applicati#</a>]
	      </if>
	    </li>
	    </multiple>
	  </if>
	  <else>
	    <li>#dotlrn-ecommerce.lt_You_have_no_applicati#</li>
	  </else>
	</ul>
      </if>
	<h2>#dotlrn-ecommerce.Your_Waiting_Lists#</h2>
	
	<if @waiting_lists:rowcount;literal@ gt 0>
	  <ul class="action-links">
	    <multiple name="waiting_lists">
	      <li> @waiting_lists.pretty_name@ <if @user_id@ ne @waiting_lists.participant_id@>(@waiting_lists.name@) </if> 

	  	<if @waiting_lists.member_state@ eq "needs approval">
		  - <font color=red>#dotlrn-ecommerce.lt_number_waiting_listsw#</font>
		</if>
		<else>
		  #dotlrn-ecommerce.A_place_is_available#<br/>		
		  <a href="@waiting_lists.register_url@" class="button">#dotlrn-ecommerce.lt_Continue_Registration#</a>
		  
		</else>

	      </li>
	    </multiple>
	  </ul>
	</if>
	<else>
	  <ul class="action-links">
	    <li>#dotlrn-ecommerce.No_waiting_lists#</li>
	  </ul>
	</else>
      </td>
    </tr>
  </table>