<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>


<h4>Course Registration</h4>
<ul>
<li><a href="../ecommerce/shopping-cart">#dotlrn-ecommerce.Shopping_Cart#</a>
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
</ul>

<h2>#dotlrn-ecommerce.Administrative_Setup#</h2>

<ul>
<if @scholarship_installed_p@ eq "1"><li><a href=../Administration/sch/>#dotlrn-ecommerce.Scholarship_Funds#</a></if>
<if @expenses_installed_p@ eq "1"><li><a href="../Administration/expenses/admin/">#dotlrn-ecommerce.Expenses#</a></if>
<li>#dotlrn-ecommerce.Instructors# - [ <a href=@instructor_community_url@>#dotlrn.Community#</a> | <a href=@instructor_community_url@/members>#dotlrn-ecommerce.List#</a> ]
<li>#dotlrn-ecommerce.Assistant_Instuctors# - [ <a href=@assistant_community_url@>#dotlrn.Community#</a> | <a href=@assistant_community_url@/members>#dotlrn-ecommerce.List#</a> ]
<li><a href="../Administration/categories/cadmin">#dotlrn-ecommerce.lt_Manage_Category_Trees#</a>
<li><a href="@relationships_category_url;noquote@">#dotlrn-ecommerce.lt_Manage_Relationship_T#</a>
<li>#dotlrn-ecommerce.Email_templates_1#
<ul>
  <li>#dotlrn-ecommerce.lt_Application_approval_# [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_approved&return_url=@return_url@">#dotlrn-ecommerce.subject#</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_application_to_j&return_url=@return_url@">#dotlrn-ecommerce.body#</a> ]
  <li>#dotlrn-ecommerce.lt_Application_approval__1# [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_A_space_has_opened_up&return_url=@return_url@">#dotlrn-ecommerce.subject#</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_A_space_has_opened_up_1&return_url=@return_url@">#dotlrn-ecommerce.body#</a> ]
  <li>#dotlrn-ecommerce.lt_Application_approval__2# [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_prereq_approved&return_url=@return_url@">#dotlrn-ecommerce.subject#</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_prereq_approved&return_url=@return_url@">#dotlrn-ecommerce.body#</a> ]
  <li>#dotlrn-ecommerce.Reject_application# [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_rejected&return_url=@return_url@">#dotlrn-ecommerce.subject#</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_application_to_j_1&return_url=@return_url@">#dotlrn-ecommerce.body#</a> ]
  <li>#dotlrn-ecommerce.lt_Reject_waiver_of_prer# [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_prereq_rejected&return_url=@return_url@">#dotlrn-ecommerce.subject#</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_prereq_rejected&return_url=@return_url@">#dotlrn-ecommerce.body#</a> ]
</ul>
</ul>

<h2 class="page-title">#dotlrn-ecommerce.System_Setup#</h2>
<ul>
<li><a href=course-attributes>#dotlrn-ecommerce.lt_Manage_Course_Attribu#</a>
</ul>
