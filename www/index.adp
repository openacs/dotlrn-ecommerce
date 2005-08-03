<master>
<property name=title>@page_title@</property>
<property name="context">@context;noquote@</property>

<STYLE TYPE="text/css">
td.list-filter-pane-big {
  background-color: #ddddff;
  vertical-align: top;
  font-size: 14px;
}
</STYLE>

<if @admin_p@ eq 1>
    <div align="right"><a href="admin"><img border=0 src=/dotlrn-catalog/images/admin.gif></a></div>
</if>
<if @view@ eq "calendar"><include src="/packages/dotlrn-ecommerce/lib/cal-view" tree_id=@tree_id@></if><else>
<include src="/packages/dotlrn-ecommerce/lib/tree-chunk" tree_id=@tree_id@ view=@view@></else>