<master>
  <property name="title">@title@</property>
  <property name="context">@context;noquote@</property>
  
  <if @user_ids@ not defined>
    <p />
    <h3>Users related to @user.first_names@ @user.last_name@ (@user.email@)</h3>
    
    <p />
    <listtemplate name="patrons"></listtemplate>
    
    <p />
    <h3>Select a patron for @user.first_names@ @user.last_name@ (@user.email@)</h3>
  </if>
  <else>
    <p />
    <h3>Select a patron for users @group_name@</h3>
  </else>
  
  <p />
  <formtemplate id="patron"></formtemplate>