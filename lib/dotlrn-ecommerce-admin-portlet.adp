<if @show_admin@>
<ul>
	<li><a href="/ecommerce/admin/products/one?product_id=@product_id@" target="blank">Product</a>
	<li><a href=@community_url;noquote@members target="blank">Registrants</a>&nbsp;@attendees@ participant<if @attendees@ ne 1>s</if><if @available_slots@ not nil>,<br />@available_slots@ available</if>
	<li>Sessions
		<ul>
		<li><a href="@community_url;noquote@calendar/view?period%5fdays=365&view=list" target="blank">@num_sessions@ Sessions</a> Scheduled.
		<li><a href="@calendar_url@cal-item-new?item_type_id=@item_type_id@&calendar_id=@calendar_id@">Add Session</a>
		</ul>
	<li><a href="@dotlrn_ecommerce_url;noquote@admin/patrons?section_id=@section_id@">Related Users</a>
	<li><a href="@dotlrn_ecommerce_url;noquote@admin/process-purchase-all?section_id=@section_id@">Purchase</a>
</ul>
</if>