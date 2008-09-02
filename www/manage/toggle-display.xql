<?xml version="1.0"?>
<queryset>

<fullquery name="toggle_display">
    <querytext>
	update ec_custom_product_field_values set display_section_p =  not display_section_p where product_id = (select product_id from dotlrn_ecommerce_section where section_id=:section_id)
    </querytext>
</fullquery>
</queryset>
