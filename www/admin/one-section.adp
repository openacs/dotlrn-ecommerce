<master>
<property name="title">@title@</property>
<property name="context">@context@</property>

<table width=100% cellpadding=0 cellspacing=0>
<tr><td width=50% valign=top>
<h2><a href="section-add-edit.tcl?course_id=@course_id@&section_id=@section_id@" title="Edit"><img src="/resources/edit.gif" border=0></a> #dotlrn-ecommerce.Section_Information#</h2> 

<include src="/packages/dotlrn-ecommerce/lib/section"  section_id="@section_id@" course_id="@course_id@" mode=display has_edit=1 return_url="one-section?section_id=@section_id@">

<a href="section-add-edit.tcl?course_id=@course_id@&section_id=@section_id@">#dotlrn-ecommerce.lt_Edit_Section_Informat#</a>

</td>
<td width=50% valign=top>
<h2>#dotlrn-ecommerce.Quick_Links#</h2>
<a href=..>#dotlrn-ecommerce.Course_Catalog#</a><br>
<a href=.>#dotlrn-ecommerce.lt_eCommerce_Administrat#</a><br>
#dotlrn-ecommerce.Course_Page# <a href="course-info?course_id=@course_id@">@course_name@</a><br>
<p>

<a href="process-purchase-all?section_id=@section_id@">#dotlrn-ecommerce.lt_Process_Purchase_for_#</a>

<h2>#dotlrn-ecommerce.Registration#</h2>

#dotlrn-ecommerce.lt_num_attendees_partici# <br>
<a href="@community_url;noquote@members">#dotlrn-ecommerce.List_Registrants#</a><br>
<a href="patrons?section_id=@section_id@">#dotlrn-ecommerce.Related_Users#</a></br>


<h2>#dotlrn-ecommerce.Public_Pages#</h2>
<include src="/packages/file-storage/lib/folder-admin" folder_id="@section_folder_id@" base_url="@public_pages_url@">

<if @attendance_show_p@>
<h2>#dotlrn-ecommerce.lt_Sessions_and_Attendan#</h2>

<include src=/packages/attendance/lib/cp-attendance community_id=@community_id@ package_id=@community_package_id@>
</if>


<if @expensetracking_show_p@>
<h2>#dotlrn-ecommerce.Expense_Tracking#</h2>

<include src=/packages/expense-tracking/lib/cp-expense-tracking community_id=@community_id@ package_id=@community_package_id@>
</if>

<h2>#dotlrn-ecommerce.Email_templates#</h2>
<a href="email-template?action=submit_app&section_id=@section_id@">#dotlrn-ecommerce.Email_t_submit_application#</a><br />
<a href="email-template?action=approve_app&section_id=@section_id@">#dotlrn-ecommerce.Email_t_approve_application#</a>

<h2>#dotlrn-ecommerce.Related_Items#</h2>

<a href="/ecommerce/admin/products/one?product_id=@product_id@">#dotlrn-ecommerce.Product#</a><br>
<a href="@community_url;noquote@">#dotlrn-ecommerce.Community_User_Pages#</a><br>
<a href="@community_url;noquote@/one-community-admin">#dotlrn-ecommerce.lt_Community_Admin_Pages#</a>


</td></tr>
</table>
