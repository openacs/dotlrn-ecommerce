ad_page_contract {
    show one course
    for now redirect to index page

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-06-02
} {
    course_id:integer,optional
    section_id:integer,optional
    cal_item_id:integer,optional
}

if {[info exists cal_item_id] && ![string equal "" $cal_item_id]} {
set course_key [db_string get_course_key "select d1.course_key from dotlrn_catalog d1,cr_items ci, (select distinct des.course_id from cal_items c,dotlrn_ecommerce_section des, dotlrn_communities dc, portal_element_map pem, portal_pages pp, portal_element_parameters pep where pep.key='calendar_id' and pep.value=c.on_which_calendar and pem.element_id=pep.element_id and pem.page_id=pp.page_id and pp.portal_id=dc.portal_id and c.cal_item_id=:cal_item_id and dc.community_id=des.community_id) d2 where d1.course_id=ci.live_revision and ci.item_id=d2.course_id" -default ""]

}



