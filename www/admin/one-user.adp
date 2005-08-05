<master>
  <property name=title>@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">user_info.first_names</property>
  <property name="displayed_object_id">@user_id@</property>

  <table width=100% cellpadding=0 cellspacing=0>
    <tr>
      <td width=50% valign=top>

	<h2>#acs-subsite.Basic_Information#</h2>

	<include src="/packages/dotlrn-ecommerce/lib/user-info" cancel="@cancel@" add_url="home" return_url="home" user_id="@user_id@" />

      </td>
      <td width=50% valign=top>

	<h2>#dotlrn-ecommerce.Order_History#</h2>
	<ul class="action-links">
	  <if @orders:rowcount@ gt 0>
	    <multiple name="orders">
	      <li><a href="@orders.order_url;noquote@">@orders.order_id@</a>; @orders.confirmed_date@</li>
	    </multiple>
	    <li><a href="ecommerce/index?user_id=@user_id@">#dotlrn-ecommerce.Order_Details#</a></li>
	  </if>
	  <else>
	    <li>#dotlrn-ecommerce.No_orders#</li>
	</else>
	</ul>

	<h2>#dotlrn-ecommerce.Applications#</h2>
	<ul class="action-links">
	  <if @sessions_with_applications@ gt 0>
	    <multiple name="sessions">
	      <li><a href="@sessions.asm_url;noquote@">@sessions.pretty_name@</a> [<a href="@sessions.edit_asm_url;noquote@">#dotlrn-ecommerce.Edit_My_Application#</a>]</li>
	    </multiple>
	  </if>
	  <else>
	    <li>#dotlrn-ecommerce.No_applications#</li>
	  </else>
	</ul>

      </td>
    </tr>
  </table>