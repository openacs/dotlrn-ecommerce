
create function inline_0()
returns integer as '
declare
  ds_id portal_datasources.datasource_id%TYPE;
begin
  ds_id := portal_datasource__new(
         ''dotlrn_ecommerce_admin_portlet'', --     name
         ''Displays the dotlrn_ecommerce_admin'' --     description
  );

  -- 4 defaults procs

  -- shadeable_p 
  perform portal_datasource__set_def_param (
         ds_id, -- 	datasource_id
         ''t'', -- 	config_required_p
         ''t'', -- 	configured_p
         ''shadeable_p'', -- 	key
         ''f'' -- 	value
  );	

  -- shaded_p 
  perform portal_datasource__set_def_param (
         ds_id, -- 	datasource_id
         ''t'', -- 	config_required_p
         ''t'', -- 	configured_p
         ''shaded_p'', -- 	key
         ''f'' -- 	value
  );	

  -- hideable_p 
  perform portal_datasource__set_def_param (
         ds_id, -- 	datasource_id
         ''t'', -- 	config_required_p
         ''t'', -- 	configured_p
         ''hideable_p'', -- 	key
         ''t'' -- 	value
  );	

  -- user_editable_p 
  perform portal_datasource__set_def_param (
         ds_id, -- 	datasource_id
         ''t'', -- 	config_required_p
         ''t'', -- 	configured_p
         ''user_editable_p'', -- 	key
         ''f'' -- 	value
  );	

  -- link_hideable_p 
  perform portal_datasource__set_def_param (
         ds_id, -- 	datasource_id
         ''t'', -- 	config_required_p
         ''t'', -- 	configured_p
         ''link_hideable_p'', -- 	key
         ''t'' -- 	value
  );	


  -- ecommerce_admin-specific procs

  -- package_id must be configured
  perform portal_datasource__set_def_param (
         ds_id, -- 	datasource_id
         ''t'', -- 	config_required_p
         ''f'', -- 	configured_p
         ''package_id'', -- 	key
         '''' -- 	value
  );	

  return 0;

end;' language 'plpgsql';
select inline_0();
drop function inline_0();


create function inline_0()
returns integer as '
declare
	foo integer;
begin
	-- create the implementation
	perform acs_sc_impl__new (
		''portal_datasource'',
		''dotlrn_ecommerce_admin_portlet'',
		''dotlrn_ecommerce_admin_portlet''
	);
  return 0;

end;' language 'plpgsql';

select inline_0();
drop function inline_0();

create function inline_0()
returns integer as '
declare
	foo integer;
begin

	-- add all the hooks
	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''GetMyName'',
	       ''dotlrn_ecommerce_admin_portlet::get_my_name'',
	       ''TCL''
	);

	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''GetPrettyName'',
	       ''dotlrn_ecommerce_admin_portlet::get_pretty_name'',
	       ''TCL''
	);

	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''Link'',
	       ''dotlrn_ecommerce_admin_portlet::link'',
	       ''TCL''
	);

	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''AddSelfToPage'',
	       ''dotlrn_ecommerce_admin_portlet::add_self_to_page'',
	       ''TCL''
	);

	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''Show'',
	       ''dotlrn_ecommerce_admin_portlet::show'',
	       ''TCL''
	);

	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''Edit'',
	       ''dotlrn_ecommerce_admin_portlet::edit'',
	       ''TCL''
	);

	perform acs_sc_impl_alias__new (
	       ''portal_datasource'',
	       ''dotlrn_ecommerce_admin_portlet'',
	       ''RemoveSelfFromPage'',
	       ''dotlrn_ecommerce_admin_portlet::remove_self_from_page'',
	       ''TCL''
	);

        return 0;

end;' language 'plpgsql';

select inline_0();
drop function inline_0();

create function inline_0()
returns integer as '
declare
	foo integer;
begin

	-- Add the binding
	perform acs_sc_binding__new (
                ''portal_datasource'', -- 	    contract_name
                ''dotlrn_ecommerce_admin_portlet'' -- 	    impl_name
	);
  return 0;

end;' language 'plpgsql';

select inline_0();
drop function inline_0();
