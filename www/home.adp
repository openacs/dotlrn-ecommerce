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

	<if @invisible_p@ true>
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
	  <if @orders:rowcount@ gt 0>
	    <multiple name="orders">
	      <li><a href="@orders.order_url;noquote@">@orders.order_id@</a>; @orders.confirmed_date@</li>
	    </multiple>
	  </if>
	  <else>
	    <li>#dotlrn-ecommerce.You_have_no_orders#</li>
	</else>
	</ul>
<if @applications_p@>
	<h2>#dotlrn-ecommerce.Your_Applications#</h2>
</if>
<else>
	<h2>#dotlrn-ecommerce.Your_Prereq_Waiver_Requests#</h2>
</else>
	<ul class="action-links">
	  <if @sessions_with_applications@ gt 0>
	    <multiple name="sessions">
		<if @admin_p@ eq 1>
		  <li> <a href="@sessions.asm_url;noquote@">@sessions.pretty_name@</a> <if @user_id@ ne @sessions.participant@>(@sessions.name@)</if>
		</if>
		<else>
		  <li> @sessions.pretty_name@ <if @user_id@ ne @sessions.participant@>(@sessions.name@)</if>
		</else>    

	<if @use_embedded_application_view_p@ ne 1> 
	 [<a href="@sessions.edit_asm_url;noquote@">#acs-kernel.common_Edit#</a>]
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
	
<if @waiting_lists:rowcount@ gt 0>
	<ul class="action-links">
	<multiple name="waiting_lists">
	<li>@waiting_lists.pretty_name@ <if @user_id@ ne @waiting_lists.participant@>(@waiting_lists.name@) </if> - <font color=red>number @waiting_lists.waiting_list_number@ on waiting list</font></li>
	</li>
        </multiple>
	</ul>
</if>
<else>
No waiting lists
</else>
      </td>
    </tr>
  </table>