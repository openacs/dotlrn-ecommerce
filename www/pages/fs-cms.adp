<master>
<property name="title">@current_item.title;noquote@</property>
<property name="blackbackground_p">@blackbackground_p@</property>
<if @index_p@ true>
<multiple name="sections">
<table border=0 cellpadding=0 cellspacing=0>
<tr><td><div class=darkGreen>@sections.folder_label@</div></td></tr>
<tr><td style="background: url(/images/green-dots-on-black.gif)"><img 
  src="/images/green-dots-on-black.gif" width=160 height=6></td></tr>
</table>
<ul class=greendot>
<group column="folder_id">
<li><if @sections.pdf_p@ eq 1><img src="/graphics/csm/acrobat.gif" border=1 style="border-color:#AAA" /></if>
      <a class=whitelink href="@sections.item_path@"><span style="font-size: 10pt">@sections.item_label@</span></a></li>
</group>
</ul>
<p>
</multiple>
</if>
@current_item.content;noquote@
<table width="100%" border="0">
<tr>
   <td align="right"><include src="admin-link"></td>
</tr>
</table>
