# packages/dotlrn-ecommerce/tcl/dotlrn-ecommerce-procs.tcl

ad_library {
    
    dotlrn-ecommerce library
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-11
    @arch-tag: 83f2c08e-8bad-4fb8-8daf-73403e04c99d
    @cvs-id $Id$
}

namespace eval dotlrn_ecommerce {}

ad_proc -public dotlrn_ecommerce::notify_admins_of_waitlist {
} {
    notifies admins of what sections have reached
    the waitlist threshold
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-11
    
    @return 
    
    @error 
} {
    if {[parameter::get -parameter NotifyAdminsOfWaitlistDaily -default 0]} {
        set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
        set subject "Notification for waitlist"
        set message ""
        
        db_foreach get_sections_with_waitlist {
            select t.* 
            from (select dc.course_name, 
                         des.section_name, 
                         des.notify_waiting_number, 
                         (select count(*) 
                          from membership_rels mr, 
                               acs_rels ar 
                          where ar.rel_id = mr.rel_id 
                                and ar.object_id_one = des.community_id 
                                and mr.member_state = 'needs approval') as waitlist_n 
                  from dotlrn_catalog dc, 
                       cr_items i, 
                       dotlrn_ecommerce_section des 
                  where dc.course_id = i.live_revision 
                        and i.item_id = des.course_id 
                        and des.notify_waiting_number is not null) t 
            where waitlist_n >= notify_waiting_number
        } {
            append message "Section: $course_name - $section_name
Applicants in notify list: $waitlist_n
"
        }

        if {![empty_string_p $message]} {
            set object_id [acs_lookup_magic_object security_context_root]
            set privilege "admin"
            db_foreach get_swas {
                select p.email as email_to
                from parties p, 
                     users u, 
                     acs_permissions ap 
                where u.user_id = p.party_id 
                      and u.user_id = ap.grantee_id 
                      and ap.object_id = :object_id
                      and ap.privilege = :privilege
            } {
                acs_mail_lite::send \
                    -to_addr $email_to \
                    -from_addr $mail_from \
                    -subject $subject \
                    -body $message
            }
        }
    }
}
