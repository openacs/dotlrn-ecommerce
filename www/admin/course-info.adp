<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>

<table cellpadding=0 cellspacing=0>
<if @index@ eq "yes">
   <if @admin_p@ eq 1>
   <div align="left">
        <a href="dt-admin/course-info?course_id=@course_id@&course_name=@name@&course_key=@course_key@&index=yes" title="#dotlrn-catalog.admin_this#"><img border=0 src=images/admin.gif></a> 
   </div>
   </if>
</if>
<h3>#dotlrn-catalog.info#:</h3>
<tr>
   <td>
   <if @edit@ eq yes>
   <div align="right">
	<a href=course-add-edit?course_id=@course_id@&mode=1&index=@to_index@ title="#dotlrn-catalog.new_ver#"><img border=0 src=/resources/Edit16.gif></a>
   </div>
   </if>
   </td>
  <td>
    <b>#dotlrn-catalog.course_key#</b>
  </td>
  <td>
    
    @course_key@
   </td>
</tr>
<tr><td></td>
    <td><b>#dotlrn-catalog.course_name#</b></td><td>@name@</td>
</tr>
<tr><td></td>
    <td valign=top><b>#dotlrn-catalog.course_info#</b></td><td>@info;noquote@</td>
</tr>
<if @revision@ eq yes>
<tr><td></td>
    <td>
	<b>#dotlrn-catalog.dotlrn#:</b>
    </td>
    <td>
	<if @rel@ eq 0>
	   #dotlrn-catalog.no# 
	  <if @edit@ eq "yes">
	     <if @dotlrn_url@ eq "/dotlrn">
             (<a href="dotlrn-list?course_id=@course_id@&course_key=@course_key@&course_name=@name@&return_url=@return_url@" title="#dotlrn-catalog.associate_this#"><i>#dotlrn-catalog.associate#</i></a>)</if>
          </if>
	</if>
	<else>
	   <if @index@ eq "yes">
	       #dotlrn-catalog.yes# (<a href="dt-admin/course-details?course_id=@course_id@&course_key=@course_key@&return_url=@return_url@&course_name=@name@" title="#dotlrn-catalog.course_details#"><i>#dotlrn-catalog.watch#</i></a>)
	   </if>
	   <else>
	       #dotlrn-catalog.yes# (<a href="course-details?course_id=@course_id@&course_key=@course_key@&return_url=@return_url@&course_name=@name@" title="#dotlrn-catalog.course_details#"><i>#dotlrn-catalog.watch#</i></a>)
	   </else>
	</else>
    </td>
</tr>
</if>
<if @asm@ not eq #dotlrn-catalog.not_associated#>
    <tr><td></td>
        <td><b>#dotlrn-catalog.asm#:</b></td><td>@asm@</td>
    </tr>
</if>
<if @category_p@ eq "1">
    <if @index@ not eq "yes">
        <tr><td></td>
	   <td>
	       <b>#dotlrn-catalog.categorize#:</b>
	   </td>
    	   <td>#dotlrn-catalog.yes# (@category_name@)</td>
        </tr>
    </if>
</if>
<tr><td></td><td></td>
<td>
   <if @edit@ eq no>
      <if @index@ eq "yes">
	<if @asmid@ not eq "-1">
	    <a class="button" href="/assessment/assessment?assessment_id=@asmid@">#dotlrn-catalog.enroll#</a>
	</if>
	<else>
	   <br>
	   <b>#dotlrn-catalog.enroll_not#</b>
	</else>
      </if>
      <else>
         <if @course_id@ eq @live_revision@>
	     <img border=0 src="/dotlrn-catalog/images/live.gif">   
         </if>
         <else>
	     <a href="go-live?course_key=@course_key@&revision_id=@course_id@" title="#dotlrn-catalog.make_live#"><img border=0 src="/dotlrn-catalog/images/golive.gif"></a>
         </else>
      </else>
   </if>
   <else>
	<a class=button href=section-add-edit?course_id=@course_id@&return_url=>Add a section</a>
	<a class=button href=course-add-edit?course_id=@course_id@&mode=1>Edit</a>
         <a class=button href="course-delete?object_id=@item_id@&creation_user=@creation_user@&course_key=@course_key@" title="#dotlrn-catalog.delete_this#">#dotlrn-catalog.delete#</a>
	<if @category_p@ eq "-1">
	   <a class=button href="course-categorize?course_id=@course_id@&name=@name@">#dotlrn-catalog.categorize#</a>
	</if>
   </td>
   </else>
</tr>

<if @template_community_id@ defined>
<tr>
      <td></td>
      <td><b>Template Community:</b></td>
      <td><a href="@template_community_url;noquote@"
	class="button">User</a> <a href="@template_community_url;noquote@one-community-admin" class="button">Admin</a> <a href="@template_calendar_url;noquote@" class="button">Add Session</a></td>
</tr>
</if>

</table>

<h3>Sections</h3>

<listtemplate name=section_list></listtemplate>