create table dotlrn_club_student_rels (
    rel_id integer constraint dcs_rels_rel_id_pk primary key 
		   constraint dcs_rels_fk references membership_rels(rel_id)
);

create or replace view dcs_rels_full
as
    select acs_rels.rel_id as rel_id,
           acs_rels.object_id_one as community_id,
           acs_rels.object_id_two as user_id,
           acs_rels.rel_type,
           (select acs_rel_types.role_two
            from acs_rel_types
            where acs_rel_types.rel_type = acs_rels.rel_type) as role,
           membership_rels.member_state
    from dotlrn_club_student_rels,
         acs_rels,
         membership_rels
    where dotlrn_club_student_rels.rel_id = acs_rels.rel_id
    and acs_rels.rel_id = membership_rels.rel_id;

create or replace view dcs_rels_approved
as
    select *
    from dcs_rels_full
    where member_state = 'approved';

create or replace package dotlrn_club_student_rel
as

-- dotlrn_club_student_rel__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'membership_rel',
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dotlrn_club_student_rels.rel_id%TYPE;

-- dotlrn_club_student_rel__delete
 procedure del (
	rel_id in composition_rels.rel_id%TYPE
 );

end dotlrn_club_student_rel;
/
show errors

create or replace package body dotlrn_club_student_rel
as

-- dotlrn_club_student_rel__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'membership_rel',
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dotlrn_club_student_rels.rel_id%TYPE
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
        into dotlrn_club_student_rels
        (rel_id)
        values
        (v_rel_id);

	return v_rel_id;
 end;

-- dotlrn_club_student_rel__delete
 procedure del (
	rel_id in composition_rels.rel_id%TYPE
 )
 is
 begin
	delete 
	from dotlrn_club_student_rels 
	where rel_id = rel_id; 

	membership_rel.del(rel_id);

 end;

end dotlrn_club_student_rel;
/
show errors


create table dotlrn_club_instructor_rels (
    rel_id integer constraint dci_rels_rel_id_pk primary key 
		   constraint dci_rels_fk references membership_rels(rel_id)
); 

create or replace view dci_rels_full
as
    select acs_rels.rel_id as rel_id,
           acs_rels.object_id_one as community_id,
           acs_rels.object_id_two as user_id,
           acs_rels.rel_type,
           (select acs_rel_types.role_two
            from acs_rel_types
            where acs_rel_types.rel_type = acs_rels.rel_type) as role,
           membership_rels.member_state
    from dotlrn_club_instructor_rels,
         acs_rels,
         membership_rels
    where dotlrn_club_instructor_rels.rel_id = acs_rels.rel_id
    and acs_rels.rel_id = membership_rels.rel_id;

create view dci_rels_approved
as
    select *
    from dci_rels_full
    where member_state = 'approved';

create or replace package dotlrn_club_instructor_rel
as

-- dotlrn_club_instructor__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'membership_rel',
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dotlrn_club_instructor_rels.rel_id%TYPE;

-- dotlrn_club_student_rel__delete
 procedure delete (
	rel_id in composition_rels.rel_id%TYPE
 );

end dotlrn_club_instructor_rel;
/
show errors

create or replace package body dotlrn_club_instructor_rel
as

-- dotlrn_club_instructor_rel__new
 function new (
        rel_id in membership_rels.rel_id%TYPE default null,
        rel_type in acs_rels.rel_type%TYPE default 'membership_rel',
        community_id in dotlrn_communities.community_id%TYPE,
	user_id in users.user_id%TYPE,
        member_state in membership_rels.member_state%TYPE,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null
 ) return dotlrn_club_instructor_rels.rel_id%TYPE
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
        into dotlrn_club_instructor_rels
        (rel_id)
        values
        (v_rel_id);

	return v_rel_id;

 end new;

-- dotlrn_club_instructor_rel__delete
 procedure delete (
	rel_id in composition_rels.rel_id%TYPE
 )
 is
	v_rel_id membership_rels.rel_id%TYPE;
 begin
	delete 
	from dotlrn_club_instructor_rels 
	where rel_id = rel_id; 

	membership_rel.del(rel_id);

 end delete;

end dotlrn_club_instructor_rel;
/
show errors

