<master>
<property name="title">@page_title@</property>
<property name="context">@context@</property>
<property name="focus">add_class_instance.term</property>

<if @section_id@ eq "">
   <include src=/packages/dotlrn-ecommerce/lib/section
   course_id="@course_id@" return_url="@return_url@" item_id="@item_id@" sessions="@sessions@" />
</if>
<else>
   <include src=/packages/dotlrn-ecommerce/lib/section
   section_id=@section_id@ course_id="@course_id@"
   return_url="@return_url@" item_id="@item_id@" sessions="@sessions@" />
</else>

