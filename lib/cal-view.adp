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
    <td class="list-filter-pane-big" valign="top" width="20%">
        <listfilters name="course_list" style="course-filters"></listfilters>
    </td>
    <td valign="top">	
	<if @show_view_all@ eq "1" ><p>@currently_viewing;noquote@<p><a href=".?view=calendar&date=@date@" class="button">View All</a></p></if>
	<include src="view-@view@-display" calendar_id_list="@calendar_id_list@" item_template="@item_template@" next_month_template="@next_month_template@" prev_month_template="@prev_month_template@" date="@date@" add_p="f" link_day_p="f" period_days="@period_days@" />
    </td>
  </tr>
</table>


