<br>

<STYLE TYPE="text/css">
table.list {
  font-family: tahoma, verdana, helvetica; 
  border-collapse: collapse;
  font-size: 11px;
}
div.cal-month-event {
    font-size: 12px;
}
</STYLE>
<table cellpadding="3" cellspacing="3">
  <tr>
    <td class="list-filter-pane-big" valign="top" width=20%>
        <listfilters name="course_list" style="course-filters"></listfilters>
    </td>
    <td valign="top">
	<p><a href=".?view=calendar" class="button">View All</a></p>
<include src="view-month-display" calendar_id_list="@calendar_id_list@" item_template="@item_template@" next_month_template="@next_month_template@" prev_month_template="@prev_month_template@" date="@date@" add_p="f" link_day_p="f">
    </td>
  </tr>
</table>


