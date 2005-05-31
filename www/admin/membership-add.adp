<master>
  <property name="title">@title@</property>
  <property name="context">@context;noquote@</property>

  You are about to add user <b>@user.first_names@ @user.last_name@ (@user.email@)</b> to section <b>@section_name@</b>

  <p />
  <a href="@confirm_url;noquote@" class="button">Add Participant</a> &nbsp; <a
  href="@referer;noquote@" class="button">Cancel</a>

  <p />
  <b>You may also select a patron for this participant</b>

  <formtemplate id="patron"></formtemplate>