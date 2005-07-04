<?xml version="1.0"?>
<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.1</version>
  </rdbms>

<fullquery name="get_item_type_id">
      <querytext>
	select item_type_id from cal_item_types where type='Session' and  calendar_id = :template_calendar_id limit 1
      </querytext>
</fullquery>

<fullquery name="item_type_id">
      <querytext>
	select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id limit 1
      </querytext>
</fullquery>

</queryset>