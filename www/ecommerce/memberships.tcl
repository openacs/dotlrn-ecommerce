# packages/dotlrn-ecommerce/www/ecommerce/memberships.tcl

ad_page_contract {
    
    displays membership product chunks
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-07-14
    @arch-tag: c5741497-5c4c-43f3-a528-7d733ec5dbac
    @cvs-id $Id$
} {
    user_id:integer,notnull,optional
} -properties {
} -validate {
} -errors {
}

if {![exists_and_not_null user_id]} {
    set user_id [auth::require_login]
}

set title "Purchase membership"
set context {}

set suppress_membership_p 0
if {[parameter::get -parameter MemberPriceP -default 0]} {
    set category_id [parameter::get -parameter "MembershipECCategoryId" -default ""]
    if {[empty_string_p $category_id]} {
        set suppress_membership_p 1
    } else {
        set group_id [parameter::get -parameter MemberGroupId -default 0]
        if {$group_id} {
            set suppress_membership_p [group::member_p -group_id $group_id -user_id $user_id]
        } else {
            # just set to 1 if we do not find a group
            set suppress_membership_p 1
        }
    }
}

