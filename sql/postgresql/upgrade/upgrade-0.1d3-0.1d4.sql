-- HAM 080905
-- Add instructor and teaching assistant roles to dotlrn_community

create table dotlrn_ecom_ta_rels (
    rel_id                      integer
                                constraint dotlrn_eta_rel_id_fk
                                references membership_rels (rel_id)
                                constraint dotlrn_eta_rel_id_pk
                                primary key
);

create table dotlrn_ecom_instructor_rels (
    rel_id                      integer
                                constraint dotlrn_eti_rel_id_fk
                                references membership_rels (rel_id)
                                constraint dotlrn_eti_rel_id_pk
                                primary key
);


create or replace view dotlrn_ecom_ta_rels_full
as
    select acs_rels.rel_id as rel_id,
           acs_rels.object_id_one as community_id,
           acs_rels.object_id_two as user_id,
           acs_rels.rel_type,
           (select acs_rel_types.role_two
            from acs_rel_types
            where acs_rel_types.rel_type = acs_rels.rel_type) as role,
           membership_rels.member_state
    from dotlrn_ecom_ta_rels,
         acs_rels,
         membership_rels
    where dotlrn_ecom_ta_rels.rel_id = acs_rels.rel_id
    and acs_rels.rel_id = membership_rels.rel_id;

create or replace view dotlrn_ecom_instructor_rels_full
as
    select acs_rels.rel_id as rel_id,
           acs_rels.object_id_one as community_id,
           acs_rels.object_id_two as user_id,
           acs_rels.rel_type,
           (select acs_rel_types.role_two
            from acs_rel_types
            where acs_rel_types.rel_type = acs_rels.rel_type) as role,
           membership_rels.member_state
    from dotlrn_ecom_instructor_rels,
         acs_rels,
         membership_rels
    where dotlrn_ecom_instructor_rels.rel_id = acs_rels.rel_id
    and acs_rels.rel_id = membership_rels.rel_id;


create or replace view dotlrn_ecom_ta_rels_approved
as
    select *
    from dotlrn_ecom_ta_rels_full
    where member_state = 'approved';

create or replace view dotlrn_ecom_instructor_rels_approved
as
    select *
    from dotlrn_ecom_instructor_rels_full
    where member_state = 'approved';

select define_function_args('dotlrn_ecom_ta_rel__new','rel_id,rel_type;dotlrn_ecom_ta_rel,portal_id,community_id,user_id,member_state;approved,creation_user,creation_ip');

create or replace function dotlrn_ecom_ta_rel__new(integer,varchar,integer,integer,integer,varchar,integer,varchar)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
        p_rel_type              alias for $2;
        p_portal_id             alias for $3;
        p_community_id          alias for $4;
        p_user_id               alias for $5;
        p_member_state          alias for $6;
        p_creation_user         alias for $7;
        p_creation_ip           alias for $8;
        v_rel_id                integer;
BEGIN
        v_rel_id:= dotlrn_member_rel__new(
            p_rel_id,
            p_rel_type,
            p_portal_id,
            p_community_id,
            p_user_id,
            p_member_state,
            p_creation_user,
            p_creation_ip
        );

        insert
        into dotlrn_ecom_ta_rels
        (rel_id)
        values
        (v_rel_id);

        return v_rel_id;
END;
' language 'plpgsql';

select define_function_args('dotlrn_ecom_ta_rel__delete','rel_id');

create or replace function dotlrn_ecom_ta_rel__delete(integer)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
BEGIN
        delete from dotlrn_ecom_ta_rels where rel_id = p_rel_id; 

        PERFORM membership_rel__delete(p_rel_id);

        return 0;
END;
' language 'plpgsql';


select define_function_args('dotlrn_ecom_instructor_rel__new','rel_id,rel_type;dotlrn_ecom_instructor_rel,portal_id,community_id,user_id,member_state;approved,creation_user,creation_ip');

create or replace function dotlrn_ecom_instructor_rel__new(integer,varchar,integer,integer,integer,varchar,integer,varchar)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
        p_rel_type              alias for $2;
        p_portal_id             alias for $3;
        p_community_id          alias for $4;
        p_user_id               alias for $5;
        p_member_state          alias for $6;
        p_creation_user         alias for $7;
        p_creation_ip           alias for $8;
        v_rel_id                integer;
BEGIN
        v_rel_id:= dotlrn_member_rel__new(
            p_rel_id,
            p_rel_type,
            p_portal_id,
            p_community_id,
            p_user_id,
            p_member_state,
            p_creation_user,
            p_creation_ip
        );

        insert
        into dotlrn_ecom_instructor_rels
        (rel_id)
        values
        (v_rel_id);

        return v_rel_id;
END;
' language 'plpgsql';

select define_function_args('dotlrn_ecom_instructor_rel__delete','rel_id');

create or replace function dotlrn_ecom_instructor_rel__delete(integer)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
BEGIN
        delete from dotlrn_ecom_instructor_rels where rel_id = p_rel_id; 

        PERFORM membership_rel__delete(p_rel_id);

        return 0;
END;
' language 'plpgsql';

create function inline_0()
returns integer as '
begin

    perform acs_rel_type__create_type (
        ''dotlrn_ecom_ta_rel'',
        ''dotLRN Ecommerce Teaching Assistant Community Membership'',
        ''dotLRN Ecommerce Teaching Assistant Community Memberships'',
        ''dotlrn_member_rel'',
        ''dotlrn_ecom_ta_rels'',        
        ''rel_id'',
        ''dotlrn_ecom_ta_rel'',
        ''dotlrn_community'', 
	null, 
        0,
	null,
        ''user'',
	''teaching_assistant'',
        0,
	null
    );

    perform acs_rel_type__create_type (
        ''dotlrn_ecom_instructor_rel'',
        ''dotLRN Ecommerce Instructor Community Membership'',
        ''dotLRN Ecommerce Instructor Community Memberships'',
        ''dotlrn_member_rel'',
        ''dotlrn_ecom_instructor_rels'',        
        ''rel_id'',
        ''dotlrn_ecom_instructor_rel'',
        ''dotlrn_community'', null, 
        0, 
	null,
        ''user'', 
	''instructor'',
        0, 
	null
    );
    
    return 0;

END;
' language 'plpgsql';

select inline_0();
drop function inline_0();

