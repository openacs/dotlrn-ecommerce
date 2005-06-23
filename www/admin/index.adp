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

</ul>

<h2>Administrative Setup</h2>

<ul>
<if @scholarship_installed_p@ eq "1"><li><a href=/dotlrn-ecommerce/Administration/sch/>Scholarship Funds</a></if>
<if @expenses_installed_p@ eq "1"><li><a href="/dotlrn-ecommerce/Administration/expenses/admin/">Expenses</a></if>
<li>Instructors - <a href=@instructor_community_url@>Community</a> <a href=@instructor_community_url@/members>List</a>
<li>Assistant Instuctors - <a href=@assistant_community_url@>Community</a> <a href=@assistant_community_url@/members>List</a>
<li><a href="/dotlrn-ecommerce/Administration/categories/cadmin">Manage Category Trees</a>
<li><a href="applications">Pending Applications</a>

</ul>

<h2 class="page-title">System Setup</h2>
<ul>
<li><a href=course-attributes>Manage Course Attributes</a>
</ul>

