<master>
<property name="title">@title@</property>
<property name="context">@context@</property>

<table width=100% cellpadding=0 cellspacing=0>
<tr><td width=50% valign=top>
<h2><a href="section-add-edit.tcl?course_id=@course_id@&section_id=@section_id@" title="Edit"><img src="/resources/edit.gif" border=0></a> Section Information</h2> 

<include src=/packages/dotlrn-ecommerce/lib/section  section_id="@section_id@" course_id="@course_id@" mode=display has_edit=1 return_url="one-section?section_id=@section_id@">

<a href=section-add-edit.tcl?course_id=@course_id@&section_id=@section_id@>Edit Section Information</a>

</td>
<td width=50% valign=top>
<h2>Quick Links</h2>
<a href=.>eCommerce Administration</a><br>
Course Page: <a href=course-info?course_id=@course_id@>@course_name@</a><br>
<p>
<a href=https://mos.zill.net/dotlrn-ecommerce/admin/process-purchase-all?section_id=@section_id@>Process Purchase for @section_name@</a>


<h2>Sessions and Attendance</h2>

<include src=/packages/attendance/lib/cp-attendance community_id=@community_id@ package_id=@community_package_id@>

<h2>Registration</h2>

@num_attendees@ participants registered <br>
<a  href=@community_url@members>List Registrants</a><br>
<a href=patrons?section_id=@section_id@>Related Users</a></br>


<h2>Expense Tracking</h2>

<include src=/packages/expense-tracking/lib/cp-expense-tracking community_id=@community_id@ package_id=@community_package_id@>

<h2>Related Items</h2>

<a href=/ecommerce/admin/products/one?product_id=@product_id@>Product</a><br>
<a href=@community_url@>Community User Pages</a><br>
<a href=@community_url@/one-community-admin>Community Admin Pages</a>

</td></tr>
</table>