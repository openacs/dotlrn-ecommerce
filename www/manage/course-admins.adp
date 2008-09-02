<master>
<property name="doc(title)">@page_title@</property>
<property name="context">@context@</property>

<listtemplate name="admins"></listtemplate>
<include src="/packages/acs-authentication/lib/search"
add_permission="Add add-course-admin?object_id=@object_id@"
return_url="@return_url;noquote@"
member_url="/dotlrn/community-member"
member_admin_url="/dotlrn/admin/user"
admin_p="1"
object_id="@object_id@"
privilege="admin"
>