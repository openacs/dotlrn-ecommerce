<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>


<h4>Course Registration</h4>
<ul>
<if @shopping_cart_url@ defined>
      <li><a href="@shopping_cart_url;noquote@">#dotlrn-ecommerce.Shopping_Cart#</a>
</if>
<li><a href="process-purchase-all">#dotlrn-ecommerce.Process_Registration#</a>
<li><formtemplate id="courses">#dotlrn-ecommerce.Course_Quick_Jump# <br><formwidget
	    id="course_id" /><formwidget id="view" /></formtemplate>
<li><formtemplate id="sections">#dotlrn-ecommerce.Section_Quick_Jump# <br><formwidget
	      id="section_id" /><formwidget id="purchase" /><formwidget
		id="admin" /></formtemplate>
<li><a href=course-list>#dotlrn-ecommerce.Manage_Course_List#</a>
<if @registration_assessment_url@ defined>
<li><a href="@registration_assessment_url;noquote@">#dotlrn-ecommerce.lt_Manage_Registration_A#</a>
</if>
<li><a href="../applications">#dotlrn-ecommerce.lt_Waiting_List_and_Prer#</a>
	<ul>
		<li><a href="../applications?type=needs+approval">Users in Waiting List</a>
		<li><a href="../applications?type=waitinglist+approved">Approved Users in Waiting List</a>
		<li><a href="../applications?type=request+approval">Users for Prerequisite Approval</a>
		<li><a href="../applications?type=request+approved">Approved Users for Prerequisite Approval</a>
	</ul>
<li>#dotlrn-ecommerce.View_Orders#
<ul>
<li><a href="users">#dotlrn-ecommerce.Per_User#</a>
<li><a href="ecommerce/index?start=1%20day">#dotlrn-ecommerce.In_the_last_24_hours#</a>
<li><a href="ecommerce/index?start=7%20days">#dotlrn-ecommerce.In_the_last_week#</a>
</ul>
</ul>

<h2>#dotlrn-ecommerce.Administrative_Setup#</h2>

<ul>
<if @scholarship_installed_p@ eq "1"><li><a href=../Administration/sch/>#dotlrn-ecommerce.Scholarship_Funds#</a></if>
<if @expenses_installed_p@ eq "1"><li><a href="../Administration/expenses/admin/">#dotlrn-ecommerce.Expenses#</a></if>
<li>#dotlrn-ecommerce.Instructors# - [ <a href=@instructor_community_url@>#dotlrn.Community#</a> | <a href=@instructor_community_url@/members>#dotlrn-ecommerce.List#</a> ]
<li>#dotlrn-ecommerce.Assistant_Instuctors# - [ <a href=@assistant_community_url@>#dotlrn.Community#</a> | <a href=@assistant_community_url@/members>#dotlrn-ecommerce.List#</a> ]
<li><a href="../Administration/categories/cadmin">#dotlrn-ecommerce.lt_Manage_Category_Trees#</a>
<li>#dotlrn-ecommerce.Email_templates_1#
<ul>
  <li>#dotlrn-ecommerce.Welcome_message#[ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Welcome_to_section&return_url=@return_url@">#dotlrn-ecommerce.subject#</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Welcome_to_section_1&return_url=@return_url@">#dotlrn-ecommerce.body#</a> ]                
<if @enable_applications_p@>
  <li>Application approval (default <i>Note: this is customizable on a per section basis</i>) [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_approved&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_application_to_j&return_url=@return_url@">body</a> ]
</if>
  <li>Grant spot from waiting list [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_A_space_has_opened_up&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_A_space_has_opened_up_1&return_url=@return_url@">body</a> ]
  <li>Approve waiver of prerequisites [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_prereq_approved&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_prereq_approved&return_url=@return_url@">body</a> ]
<if @enable_applications_p@>
  <li>Reject application [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_rejected&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_application_to_j_1&return_url=@return_url@">body</a> ]
</if>
  <li>Reject waiver of prerequisites [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_prereq_rejected&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_prereq_rejected&return_url=@return_url@">body</a> ]
  <li>Purchase receipt [ <a href="/ecommerce/admin/email-templates/edit.tcl?email_template_id=1&return_url=@return_url@">edit</a> ]
</ul>
</ul>

<h2 class="page-title">#dotlrn-ecommerce.System_Setup#</h2>
<ul>
<li><a href=course-attributes>#dotlrn-ecommerce.lt_Manage_Course_Attribu#</a>
<li><a href="@portal_url@/portal-config?portal_id=@usermaster_portal_id@&referer=@return_url@">Edit Default User Portal</a>
<li><a href="@portal_url@/portal-config?portal_id=@sectionmaster_portal_id@&referer=@return_url@">Edit Default Section Portal</a>
<li><a href="/dotlrn/admin/users">User Administration</a>
<li><a href="/dotlrn/admin/toolbar-actions?action=@action@&return_url=@return_url@">@dotlrn_toolbar_action@</a></li>
<li>@ds_toggle;noquote@
</ul>


<h1>test</h1>

<include src="/packages/dotlrn-ecommerce/lib/email-templates" community_id="" course_name="">