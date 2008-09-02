# packages/dotlrn-ecommerce/www/admin/course-attributes-delete.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-24
    @arch-tag: 3531c32e-3d16-4e9c-a58b-0b4c6651f82f
    @cvs-id $Id$
} {
    name:multiple
} -properties {
} -validate {
} -errors {
}

foreach attribute $name {
    content::type::attribute::delete \
	-content_type dotlrn_catalog \
	-attribute_name $attribute \
	-drop_column 1
}

util_memoize_flush [list package_object_attribute_list_cached -start_with dotlrn_catalog -include_storage_types type_specific dotlrn_catalog]

ad_returnredirect course-attributes