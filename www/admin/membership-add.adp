<master>
  <property name="title">@title@</property>
  <property name="context">@context;noquote@</property>

  <h3>Select a patron for @user.first_names@ @user.last_name@ (@user.email@)</h3>

  <p />
  <formtemplate id="patron"></formtemplate>

  <p />
  <h3>Other users related to @user.first_names@ @user.last_name@ (@user.email@)</h3>
  
  <p />
  <listtemplate name="patrons"></listtemplate>