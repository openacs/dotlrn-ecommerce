<master>
  <property name="title">@title@</property>
  <property name="context">{process-purchase-all {Process Purchase}} {@title@}</property>

  <if @participants:rowcount@ defined>
    <h3>Detailed search results:</h3>
    <listtemplate name="participants"></listtemplate>
    <p />
  </if>

  <formtemplate id="participant"></formtemplate>