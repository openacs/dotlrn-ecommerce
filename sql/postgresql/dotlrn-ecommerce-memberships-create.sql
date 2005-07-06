-- plpgsql procedures for dotlrn catalog

-- create new rel types for club/student


create table dc_student_rels (
    rel_id                      integer
                                constraint dotlrn_club_student_rels_rel_id_fk
                                references membership_rels (rel_id)
                                constraint dotlrn_club_student_rels_rel_id_pk
                                primary key
);                                          

create or replace view dc_student_rels_full
as
    select acs_rels.rel_id as rel_id,
           acs_rels.object_id_one as community_id,
           acs_rels.object_id_two as user_id,
           acs_rels.rel_type,
           (select acs_rel_types.role_two
            from acs_rel_types
            where acs_rel_types.rel_type = acs_rels.rel_type) as role,
           membership_rels.member_state
    from dc_student_rels,
         acs_rels,
         membership_rels
    where dc_student_rels.rel_id = acs_rels.rel_id
    and acs_rels.rel_id = membership_rels.rel_id;

create or replace view dc_student_rels_approved
as
    select *
    from dc_student_rels_full
    where member_state = 'approved';
 
select define_function_args('dc_student_rel__new','rel_id,rel_type;dc_student_rel,portal_id,community_id,user_id,member_state;approved,creation_user,creation_ip');

create or replace function dc_student_rel__new(integer,varchar,integer,integer,integer,varchar,integer,varchar)
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
        into dc_student_rels
        (rel_id)
        values
        (v_rel_id);

        return v_rel_id;
END;
' language 'plpgsql';


select define_function_args('dc_student_rel__delete','rel_id');

create or replace function dc_student_rel__delete(integer)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
BEGIN
        delete from dc_student_rels where rel_id = p_rel_id; 

        PERFORM membership_rel__delete(p_rel_id);

        return 0;
END;
' language 'plpgsql';




create table dc_instructor_rels (
    rel_id                      integer
                                constraint dotlrn_club_instructor_rels_rel_id_fk
                                references membership_rels (rel_id)
                                constraint dotlrn_club_instructor_rels_rel_id_pk
                                primary key
);                                          

create or replace view dc_instructor_rels_full
as
    select acs_rels.rel_id as rel_id,
           acs_rels.object_id_one as community_id,
           acs_rels.object_id_two as user_id,
           acs_rels.rel_type,
           (select acs_rel_types.role_two
            from acs_rel_types
            where acs_rel_types.rel_type = acs_rels.rel_type) as role,
           membership_rels.member_state
    from dc_instructor_rels,
         acs_rels,
         membership_rels
    where dc_instructor_rels.rel_id = acs_rels.rel_id
    and acs_rels.rel_id = membership_rels.rel_id;

create or replace view dc_instructor_rels_approved
as
    select *
    from dc_instructor_rels_full
    where member_state = 'approved';
 
select define_function_args('dc_instructor_rel__new','rel_id,rel_type;dc_instructor_rel,portal_id,community_id,user_id,member_state;approved,creation_user,creation_ip');

create or replace function dc_instructor_rel__new(integer,varchar,integer,integer,integer,varchar,integer,varchar)
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
        into dc_instructor_rels
        (rel_id)
        values
        (v_rel_id);

        return v_rel_id;
END;
' language 'plpgsql';


select define_function_args('dc_instructor_rel__delete','rel_id');

create or replace function dc_instructor_rel__delete(integer)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
BEGIN
        delete from dc_instructor_rels where rel_id = p_rel_id; 

        PERFORM membership_rel__delete(p_rel_id);

        return 0;
END;
' language 'plpgsql';

