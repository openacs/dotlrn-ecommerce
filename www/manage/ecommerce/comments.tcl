#  www/[ec_url_concat [ec_url] /admin]/orders/comments.tcl
ad_page_contract {
  Add and edit comments for an order.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id $Id$
  @author ported by Jerry Asher (jerry@theashergroup.com)
} {
  order_id:integer,notnull
}

ad_require_permission [ad_conn package_id] admin

set doc_body ""

append doc_body "<form method=post action=comments-edit>
[export_form_vars order_id]

Please add or edit comments below:

<br>

<blockquote>
<textarea name=cs_comments rows=15 cols=50 wrap>[db_string comments_select "select cs_comments from ec_orders where order_id=:order_id"]</textarea>
</blockquote>

<p>
<center>
<input type=submit value=\"Submit\">
</center>

</form>"

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "Comments"]