<STYLE TYPE="text/css">
table.list {
  font-family: tahoma, verdana, helvetica; 
  border-collapse: collapse;
  font-size: 11px;
}
</STYLE>

<table cellpadding="3" cellspacing="3" border="0">
  <tr>
<if @show_filters_p@>
    <td class="list-filter-pane-big" valign="top" width="20%">
      <listfilters name="course_list" style="course-filters"></listfilters> 
    </td> </if>
    <td valign="top">
<if @show_filters_p@>	<listfilters name="course_list" style="listed-filters"></listfilters></if>
	<br />
	<listtemplate name="course_list" style="courses"></listtemplate>
    </td>
  </tr>
</table>
