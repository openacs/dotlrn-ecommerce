ad_library {
    Tests using includes
}

aa_register_case dotlrn_ecommerce_include_folder_links {
    Test folder links include
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {
	    foreach section_id [db_list get_sections \
				    "select section_id from
                                     dotlrn_ecommerce_section"] {
		set errmsg ""
		util_memoize_flush [list dotlrn_ecommerce::section::fs_chunk $section_id]
		set state [catch {set fs_chunk [util_memoize [list dotlrn_ecommerce::section::fs_chunk $section_id]]} errmsg]
		aa_false "Section '${section_id}' fs_chunk successfully built errmsg='${errmsg}'" $state

#   set fs_chunk [util_memoize [list dotlrn_ecommerce::section::fs_chunk $section_id] $memoize_max_age]
	    }
	}
}