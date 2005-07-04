
declare
  ds_id portal_datasources.datasource_id%TYPE;
begin
  ds_id := portal_datasource.new(
    name             => 'dotlrn_ecommerce_admin_portlet',
    description      => 'Displays the dotlrn_ecommerce_admin'
  );

  -- 4 defaults procs

  -- shadeable_p 
  portal_datasource.set_def_param (
	datasource_id => ds_id,
	config_required_p => 't',
	configured_p => 't',
	key => 'shadeable_p',
	value => 'f'
);	

  -- shaded_p 
  portal_datasource.set_def_param (
	datasource_id => ds_id,
	config_required_p => 't',
	configured_p => 't',
	key => 'shaded_p',
	value => 'f'
);	

  -- hideable_p 
  portal_datasource.set_def_param (
	datasource_id => ds_id,
	config_required_p => 't',
	configured_p => 't',
	key => 'hideable_p',
	value => 't'
);	

  -- user_editable_p 
  portal_datasource.set_def_param (
	datasource_id => ds_id,
	config_required_p => 't',
	configured_p => 't',
	key => 'user_editable_p',
	value => 'f'
);	

  -- link_hideable_p 
  portal_datasource.set_def_param (
	datasource_id => ds_id,
	config_required_p => 't',
	configured_p => 't',
	key => 'link_hideable_p',
	value => 't'
);	


  -- ecommerce_admin-specific procs

  -- package_id must be configured
  portal_datasource.set_def_param (
	datasource_id => ds_id,
	config_required_p => 't',
	configured_p => 'f',
	key => 'package_id',
	value => ''
);	


end;
/
show errors


declare
	foo integer;
begin
	-- create the implementation
	foo := acs_sc_impl.new (
		impl_contract_name => 'portal_datasource',
		impl_name => 'dotlrn_ecommerce_admin_portlet',
		impl_pretty_name => 'dotlrn_ecommerce_admin_portlet',
		impl_owner_name => 'dotlrn_ecommerce_admin_portlet'
	);

end;
/
show errors

declare
	foo integer;
begin

	-- add all the hooks
	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'GetMyName',
	       'dotlrn_ecommerce_admin_portlet::get_my_name',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'GetPrettyName',
	       'dotlrn_ecommerce_admin_portlet::get_pretty_name',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'Link',
	       'dotlrn_ecommerce_admin_portlet::link',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'AddSelfToPage',
	       'dotlrn_ecommerce_admin_portlet::add_self_to_page',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'Show',
	       'dotlrn_ecommerce_admin_portlet::show',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'Edit',
	       'dotlrn_ecommerce_admin_portlet::edit',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'portal_datasource',
	       'dotlrn_ecommerce_admin_portlet',
	       'RemoveSelfFromPage',
	       'dotlrn_ecommerce_admin_portlet::remove_self_from_page',
	       'TCL'
	);

end;
/
show errors

declare
	foo integer;
begin

	-- Add the binding
	acs_sc_binding.new (
	    contract_name => 'portal_datasource',
	    impl_name => 'dotlrn_ecommerce_admin_portlet'
	);
end;
/
show errors

