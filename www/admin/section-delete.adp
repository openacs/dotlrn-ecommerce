<master>
<property name="title">@page_title@</property>
<property name="context">@context@</property>

@content;noquote@

<p />

<if @attendees@ le 0>
    <formtemplate id="delete_section"></formtemplate>
</if>
<else>
    <a href="@return_url;noquote@" class="button">Back</a>
</else>