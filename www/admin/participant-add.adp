<master>
  <property name="title">@title@</property>
  <property name="context">@context@</property>

  <include src="/packages/dotlrn-ecommerce/lib/user-info"
    user_id="@user_id@"
    edit_p=1
    return_url="@return_url;noquote@"
    section_id=@section_id@
    add_url="@add_url;noquote@"
    cancel="@cancel@" />