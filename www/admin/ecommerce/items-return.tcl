ad_page_contract {

    Return items.

    @author Eve Andersson (eveander@arsdigita.com)
    @creation-date Summer 1999
    @author ported by Jerry Asher (jerry@theashergroup.com)
    @author revised by Bart Teeuwisse (bart.teeuwisse@thecodemill.biz)
    @revision-date April 2002

} {
    order_id:integer,notnull
}

ad_require_permission [ad_conn package_id] admin

# In case they reload this page after completing the refund process:

if { [db_string doubleclick_select "
    select count(*) 
    from ec_items_refundable 
    where order_id=:order_id"] == 0 } {
    
    ad_return_complaint 1 "
	<li>This order doesn't contain any refundable items; perhaps you are using an old form. <a href=\"one?[export_url_vars order_id]\">Return to the order.</a>"
    return
}

set doc_body ""

# Generate the new refund_id to prevent reusing this form.

set refund_id [db_nextval refund_id_sequence]

append doc_body "
    <form method=post action=items-return-2>
      [export_form_vars order_id refund_id]

      <blockquote>
        <p>Date received back: [ad_dateentrywidget received_back_date]&nbsp;[ec_timeentrywidget received_back_time]</p>

	<p>Please check off the items that were received back:</p>
 	<blockquote>
          [ec_items_for_fulfillment_or_return $order_id "f"]
        </blockquote>

	<p>Reason for return (if known):</p>
	<blockquote>
	  <textarea name=reason_for_return rows=5 cols=50 wrap></textarea>
	</blockquote>
      </blockquote>

      <center><input type=submit value=\"Continue\"></center>
    </form>"

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "Refund"]