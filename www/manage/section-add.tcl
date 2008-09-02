ad_page_contract {
    Displays information of one course
    @author          Tracy Adams (teadams@alum.mit.edu)
} {
    course_id:notnull
    section_id:optional
    {return_url "" }
}



ad_form -name add_section -form {
    section_id:key
    {return_url:text(hidden) {value $return_url}}
    {course_id:text(hidden) {value $course_id}}
    {section_name:text}     

} -new_data {

    db_transaction {

	set community_id [dotlrn_club::new  -pretty_name $section_name] 


	db_dml add_section {
	    insert into dotlrn_ecommerce_section(section_id, course_id, section_name, community_id) values
	    (:section_id, :course_id, :section_name, :community_id)
	}


    }

    ad_returnredirect $return_url


} -edit_data {


} -new_request {

} -edit_request {

}


#create table dotlrn_ecommerce_section (
#	section_id      integer primary key,
#	community_id    integer references dotlrn_communities_all(community_id),
#	section_name	varchar(2000),
#	age		varchar(2000),
#	date_time_start timestamptz,  	   
#	date_time_end	timestamptz,
#	daily_p		char(1) check (daily_p in ('t','f')),
#	weekly_p        char(1) check (weekly_p in ('t','f')),	
#	qualified_age_low   integer,
#	qualified_age_high  integer,
#	account_code_revenue varchar(100),
#	account_code_expense varchar(100),
#	max_participants     integer,
#	waiting_list_p       char(1) check (daily_p in ('t','f')),
#	notify_waiting_number integer,
#	member_price_number   numeric,
#	non_member_price      numeric
#);



