<table class="cal-table-display" cellpadding="0" cellspacing="0" border="0" width="99%">
  <tr>
    <td class="cal-month-title-text" colspan="7" align="center">
      <a href="@previous_month_url;noquote@"><img border=0 src="<%=[dt_left_arrow]%>" alt="back one month"></a>
      @month_string@ @year@
      <a href="@next_month_url;noquote@"><img border=0 src="<%=[dt_right_arrow]%>" alt="forward one month"></a>
    </td>
  </tr>
  <tr>
    <td align="center">

      <table class="cal-month-table" cellpadding="2" cellspacing="2" border="5">
        <tbody>
          <tr>
            <multiple name="weekday_names">
              <td width="14%" class="cal-month-day-title">
                @weekday_names.weekday_short@
              </td>
            </multiple>
          </tr>

          <tr>
            <multiple name="items">
              <if @items.beginning_of_week_p@ true>
                <tr>
              </if>

              <if @items.outside_month_p@ true>
                <td class="cal-month-day-inactive">&nbsp;</td>
              </if>     
              <else>
                <if @items.today_p@ true>
                  <td class="cal-month-today" <if @add_p@> onclick="javascript:location.href='@items.add_url@';"</if>>
                </if>
                <else>
                  <td class="cal-month-day" <if @add_p@>onclick="javascript:location.href='@items.add_url@';"</if>>
                </else>
                  <if @items.day_url@ not nil><a href="@items.day_url@">@items.day_number@</a></if><else>@items.day_number@</else>
	
                  <group column="day_number">
                    <if @items.event_name@ true>
                      <div class="cal-month-event">
                        <if @items.time_p@ true>
				<if @items.fontcolor@ not nil><font color="@items.fontcolor@">@items.ansi_start_time@</font></if><else>@items.ansi_start_time@</else>				
			</if>
                        <a href=@items.event_url@>@items.calendar_name@</a>
                        </if>
                      </div>
                    </if>
                  </group>
                </td>
              </else>
              <if @items.end_of_week_p@ true>
                </tr>
              </if>
            </multiple>

          </tr>
        </tbody>
      </table>
    </td>
  </tr>
</table>
<table cellpaddin=2 cellspacing=2 border=0>
	<tr>
		<td bgcolor="#1958B7">&nbsp;&nbsp;</td><td>Before 12pm</td>
		<td bgcolor="#E7911E">&nbsp;&nbsp;</td><td>Between 12pm and 5pm</td>
		<td bgcolor="#A7C3FE">&nbsp;&nbsp;</td><td>After 5pm</td>
	</tr>
</table> 



