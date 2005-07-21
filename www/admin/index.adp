<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>


<h4>Course Registration</h4>
<ul>
<li><a href="process-purchase-all">Process Registration</a>
<li><formtemplate id="courses">Course Quick Jump <br><formwidget
	    id="course_id" /><formwidget id="view" /></formtemplate>
<li><formtemplate id="sections">Section Quick Jump <br><formwidget
	      id="section_id" /><formwidget id="purchase" /><formwidget
		id="admin" /></formtemplate>
<li><a href=course-list>Manage Course List</a>
<if @registration_assessment_url@ defined>
<li><a href="@registration_assessment_url;noquote@">Manage Registration Assessment</a>
</if>
<li><a href="../applications?type=pending">Pending Applications</a> (@pending_count@)
<li><a href="../applications?type=request">User Requests for Applications (@request_count@)
</ul>

<h2>Administrative Setup</h2>

<ul>
<if @scholarship_installed_p@ eq "1"><li><a href=../Administration/sch/>Scholarship Funds</a></if>
<if @expenses_installed_p@ eq "1"><li><a href="../Administration/expenses/admin/">Expenses</a></if>
<li>Instructors - <a href=@instructor_community_url@>Community</a> <a href=@instructor_community_url@/members>List</a>
<li>Assistant Instuctors - <a href=@assistant_community_url@>Community</a> <a href=@assistant_community_url@/members>List</a>
<li><a href="../Administration/categories/cadmin">Manage Category Trees</a>
<li><a href="../applications">Pending Applications</a>
<li><a href="@relationships_category_url;noquote@">Manage Relationship Types</a>
<li>Email templates
<ul>
  <li>Application approval (default <i>Note: this is customizable on a per section basis</i>) [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_approved&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_application_to_j&return_url=@return_url@">body</a> ]
  <li>Application approval (granted spot from waiting list) [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_A_space_has_opened_up&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_A_space_has_opened_up_1&return_url=@return_url@">body</a> ]
  <li>Application approval (waiver of prerequisites approved) [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_prereq_approved&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_prereq_approved&return_url=@return_url@">body</a> ]
  <li>Reject application [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_rejected&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_application_to_j_1&return_url=@return_url@">body</a> ]
  <li>Reject waiver of prerequisites [ <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=Application_prereq_rejected&return_url=@return_url@">subject</a> | <a href="/acs-lang/admin/edit-localized-message?package_key=dotlrn-ecommerce&locale=@package_locale@&message_key=lt_Your_prereq_rejected&return_url=@return_url@">body</a> ]
</ul>
</ul>

<h2 class="page-title">System Setup</h2>
<ul>
<li><a href=course-attributes>Manage Course Attributes</a>
</ul>
