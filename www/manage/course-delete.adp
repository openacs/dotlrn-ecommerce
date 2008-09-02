<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>
<br>
#dotlrn-catalog.this_course# <b>@rev_num@</b> 
<if @assoc_num@ eq 1>
    #dotlrn-catalog.version#
</if>
<else>
    #dotlrn-catalog.versions#
</else>

<if @assoc_num@ eq 0>
   #dotlrn-catalog.has_no#
</if>
<else>
   <if @assoc_num@ eq 1>
       #dotlrn-catalog.and_has_one#
   </if>
   <else>
       #dotlrn-catalog.and_has# <b>@assoc_num@</b> #dotlrn-catalog.to_dotlrn#
   </else>
</else>
<br>
<if @sections@ eq 0>
<b>#dotlrn-catalog.do_you_still#</b>
<br><br>
	    <formtemplate id="delete_course"></formtemplate>
</if>
<else>
	    There are <b>@sections@</b> section(s) under this course
	    and it cannot be deleted.
</else>