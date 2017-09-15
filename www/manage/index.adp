<master>
<property name="doc(title)">@doc_title@</property>
<property name="context">@context@</property>

<h1>@doc_title@</h1>

<form action="index" method="GET">
    #dotlrn-catalog.search_courses# 
    <input name="keyword" onfocus="if(this.value=='#dotlrn-catalog.please_type#')this.value='';" onblur="if(this.value=='')this.value='#dotlrn-catalog.please_type#';" value="@keyword_value@" size=40 />
    <input type="submit" value="#dotlrn-catalog.search#" />
</form>
<br>
<if @admin_p;literal@ true><a class=button href="course-add-edit">#dotlrn-catalog.new_course#</a>
<br></if>
<br>

<listtemplate name="courses"></listtemplate>
