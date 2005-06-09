<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>

<ul>
<li><a href="process-purchase-all">Registration: Administrator Interface</a>
<li><a href=course-list>Manage Course List</a>
<li><a href=course-attributes>Manage Course Attributes</a>
<li><a href="/categories/cadmin">#dotlrn-catalog.admin_categories#</a>
<li>Instructors - <a href=@instructor_community_url@>Community</a> <a href=@instructor_community_url@/members>List</a>
<li>Assistant Instuctors - <a href=@assistant_community_url@>Community</a> <a href=@assistant_community_url@/members>List</a>
<if @scholarship_installed_p@ eq "1"><li><a href=/sf>Scholarship Funds</a></if>
<if @expenses_installed_p@ eq "1"><li><a href="/expenses/admin/">Expenses</a></if>
<li><a href="process-purchase-all">Process Purchases</a>
</ul>
