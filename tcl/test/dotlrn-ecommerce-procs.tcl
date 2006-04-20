# packages/dotlrn-ecommerce/tcl/test/dotlrn-ecommerce-procs.tcl

ad_library {
    
    Tests for dotlrn ecommerce
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-04-20
    @cvs-id $Id$
}

aa_register_case -cats api util_param_get_default {
    Test that dotlrn_ecommerc::util::param::get returns the default we
    passed in if the parameter is not set (instead of always empty
    string)
} {
    # make sure the parameter does not exist, use a fake name
    set param_name [ns_mktemp __does_not_exist_XXXXXX]
    set param_default _the_default_
    set param_value [dotlrn_ecommerce::util::param::get \
                         -default $param_default \
                         $param_name]
    aa_true "Correct default '${param_value}' matches '${param_default}'" \
        [expr {$param_default eq $param_value}]
} 