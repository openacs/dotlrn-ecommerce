create table dc_student_rels (
    rel_id integer constraint dcs_rels_rel_id_pk primary key 
		   constraint dcs_rels_fk references membership_rels(rel_id)
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

create or replace package dc_student_rel
as

-- dc_student_rel__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'membership_rel',
	portal_id in portals.portal_id%TYPE,
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dc_student_rels.rel_id%TYPE;

-- dc_student_rel__delete
 procedure del (
	rel_id in composition_rels.rel_id%TYPE
 );

end dc_student_rel;
/
show errors

create or replace package body dc_student_rel
as

-- dc_student_rel__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'membership_rel',
	portal_id in portals.portal_id%TYPE,
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dc_student_rels.rel_id%TYPE
 is
	v_rel_id membership_rels.rel_id%TYPE;
 begin
        v_rel_id:= dotlrn_member_rel.new(
            rel_id => rel_id,
            rel_type => rel_type,
            community_id => community_id,
	    user_id => user_id,
            member_state => member_state,
            creation_user => creation_user,
            creation_ip => creation_ip
        );

        insert
        into dc_student_rels
        (rel_id)
        values
        (v_rel_id);

	return v_rel_id;
 end;

-- dc_student_rel__delete
 procedure del (
	rel_id in composition_rels.rel_id%TYPE
 )
 is
 begin
	delete 
	from dc_student_rels 
	where rel_id = rel_id; 

	membership_rel.del(rel_id);

 end;

end dc_student_rel;
/
show errors


create table dc_instructor_rels (
    rel_id integer constraint dci_rels_rel_id_pk primary key 
		   constraint dci_rels_fk references membership_rels(rel_id)
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

create or replace package dc_instructor_rel
as

-- dc_instructor__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'dc_instructor_rel',
        community_id in dotlrn_communities.community_id%TYPE,	
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dc_instructor_rels.rel_id%TYPE;

-- dc_instructor_rel__delete
 procedure delete (
	rel_id in composition_rels.rel_id%TYPE
 );

end dc_instructor_rel;
/
show errors

create or replace package body dc_instructor_rel
as

-- dc_instructor_rel__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'dc_instructor_rel',
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dc_instructor_rels.rel_id%TYPE
 is
	v_rel_id membership_rels.rel_id%TYPE;
 begin
        v_rel_id:= dotlrn_member_rel.new(
            rel_id => rel_id,
            rel_type => rel_type,
            community_id => community_id,
            user_id => user_id,
            member_state => member_state,
            creation_user => creation_user,
            creation_ip => creation_ip
        );

        insert
        into dc_instructor_rels
        (rel_id)
        values
        (v_rel_id);

	return v_rel_id;

 end new;

-- dc_instructor_rel__delete
 procedure delete (
	rel_id in composition_rels.rel_id%TYPE
 )
 is
	v_rel_id membership_rels.rel_id%TYPE;
 begin
	delete 
	from dc_instructor_rels 
	where rel_id = rel_id; 

	membership_rel.del(rel_id);

 end delete;

end dc_instructor_rel;
/
show errors

