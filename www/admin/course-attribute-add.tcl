# packages/dotlrn-ecommerce/www/admin/course-attribute-add.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-24
    @arch-tag: 95d276e0-dd4f-4ab1-bf84-02369541f50d
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

set attribute_list [package_object_attribute_list -start_with dotlrn_catalog dotlrn_catalog]
set sort_order [expr [llength $attribute_list] + 1]

ad_form -name attribute -export {sort_order} -form {
    {name:text {label "Attribute Name"}
	{help_text "Unique key to identify the attribute"}
    }
    {title:text {label "Title"}}
    {widget:text(select) {label "Widget"} {options {
	{"String (textfield)" string} \
	    {"Text (textbox)" text} \
	    {Integer integer} \
	    {Boolean boolean}
    }}}
} -on_submit {
    array set spec [list string text text text integer integer boolean boolean]

    content::type::attribute::new \
	-content_type "dotlrn_catalog" \
	-attribute_name $name \
	-datatype $widget \
	-pretty_name $title \
	-sort_order $sort_order \
	-column_spec $spec($widget)
    
    util_memoize_flush [list package_object_attribute_list_cached -start_with dotlrn_catalog -include_storage_types type_specific dotlrn_catalog]
    util_memoize_flush [list package_object_attribute_list_cached -start_with acs_object -include_storage_types type_specific dotlrn_catalog]

    ad_returnredirect course-attributes
    ad_script_abort
}