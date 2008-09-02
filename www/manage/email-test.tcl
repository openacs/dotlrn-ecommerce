ad_page_contract {

    Send a test email

} {
    community_id
    type
    return_url
}
acs_user::get -user_id [ad_conn user_id] -array user

set email_data [dotlrn_community::send_member_email -community_id $community_id -type $type -to_user $user(user_id)]

set page_title "[_ dotlrn-ecommerce.Test_email_sent]"
set context [list $page_title]
