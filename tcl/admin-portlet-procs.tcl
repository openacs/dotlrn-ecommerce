# packages/dotlrn-ecommerce/tcl/admin-portlet-procs.tcl

ad_library {
    
    Library admin portlet procs
    
    @author Hamilton Chua (hamilton.chua@gmail.com)
    @creation-date 2005-06-10
    @cvs-id $Id$
}

namespace eval dotlrn_ecommerce_admin_portlet {

ad_proc -private get_my_name {
    } {
	return "dotlrn_ecommerce_admin_portlet"
    }

    ad_proc -public get_pretty_name {
    } {
	return "Section Administration"
    }

    ad_proc -private my_package_key {
    } {
        return "dotlrn-ecommerce"
    }

    ad_proc -public link {
    } {
        return ""
    }

    ad_proc -public add_self_to_page {
	{-portal_id:required}
        {-package_id:required}
    } {
	Adds a dotlrn-ecommerce admin PE to the admin portal

        @return new element_id
    } {
        return [portal::add_element_parameters \
            -portal_id $portal_id \
            -portlet_name [get_my_name] \
            -pretty_name [get_pretty_name] \
            -key package_id \
            -value $package_id
        ]
    }

    ad_proc -public remove_self_from_page {
        {-portal_id:required}
    } {
        Removes the dotlrn-ecommerce admin PE from the portal
    } {
        portal::remove_element \
            -portal_id $portal_id \
            -portlet_name [get_my_name]
    }

    ad_proc -public show {
	cf
    } {
    } {
        portal::show_proc_helper \
            -package_key [my_package_key] \
            -config_list $cf \
            -template_src "/packages/dotlrn-ecommerce/lib/dotlrn-ecommerce-admin-portlet"
    }

    ad_proc -public edit {
        cf
    } {
    } {
	return ""
    }


}