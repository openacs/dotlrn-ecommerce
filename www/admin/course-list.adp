<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>

<STYLE TYPE="text/css">
table.list {
  font-family: tahoma, verdana, helvetica; 
  border-collapse: collapse;
  font-size: 12px;
}
</STYLE>
<p>

<form action="course-list" method="GET">
    #dotlrn-catalog.search_courses# 
    <input name="keyword" onfocus="if(this.value=='Please enter Course Name or Course Key')this.value='';" onblur="if(this.value=='')this.value='#dotlrn-catalog.please_type#';" value="#dotlrn-catalog.please_type#" size=40 />
    <input type="submit" value="#dotlrn-catalog.search#" />
</form>
<br>
<a class=button href="course-add-edit">#dotlrn-catalog.new_course#</a>
<br>
<listtemplate name=course_list></listtemplate>

<br>
<a class=button href="course-add-edit">#dotlrn-catalog.new_course#</a>
<p>


