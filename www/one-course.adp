<master>
<property name="title">Course Info: @course_name@</property>
<h1 style="font-size: 14px; color: #BBBBBB;">Course Information:</h1>
<h1>@course_name@</h1>
<div style="float:left; width:45%; margin-right:4%;">
<h3>Course Key: @course_key@</h3>
<multiple name="sections">
<if @sections.rownum@ eq 1>
<h3>Course Description</h3>
<p>@sections.course_info@</p>
<multiple name="categories">
<h3>Categories</h3>
<p>@categories.category_names@</p>
</multiple>
</if>
</multiple>
<if @admin_p;literal@ true>
<p>Admin: <a href="@course_edit_url@">#dotlrn-ecommerce.edit#</a></p>
</if>

</div>
<div style="float:left; width:45%;">
<h3>Available Section(s)</h3>
<multiple name="sections">
<div style="clear:both; padding-bottom:20px; padding-right:10px; padding-left:10px; padding-top:0px; margin:5px; border:1px solid; width:300px;">
<h3>@sections.section_name@</h3>
<if @admin_p;literal@ true>
<p>Admin: <a href="@sections.section_edit_url;noquote@" class="admin-button">#dotlrn-ecommerce.edit#</a>
	<if @sections.toggle_display_url@ not nil><if @sections.display_section_p;literal@ false>#dotlrn-ecommerce.This_section_is_hidden# <a href="@sections.toggle_display_url;noquote@" class="admin-button">#dotlrn-ecommerce.Show_this_section#</a></if><else><a href="@sections.toggle_display_url;noquote@" class="admin-button">#dotlrn-ecommerce.Hide_this_section#</else></a></if></p>	

</if>
<p>@sections.description;noquote@</p>
		<if @sections.sessions@ not nil and @sections.show_sessions_p@ eq "t"><br />@sections.sessions;noquote@</if>
		<if @sections.section_zones@ not nil><br />@sections.section_zones;noquote@</if>
		<if @sections.instructor_names@ not nil><br />@sections.instructor_names;noquote@</if>
		<if @sections.prices@ not nil and @sections.show_price_p@ true><br /><if @allow_free_registration_p;literal@ true and @sections.price@ lt 0.01>#dotlrn-ecommerce.lt_There_is_no_fee_for_t#</if><else>@sections.prices;noquote@</else></if>
		<if @sections.show_participants_p;literal@ true>
		<br />@sections.attendees;noquote@ #dotlrn-ecommerce.participant#<if @sections.attendees@ gt 1>s</if>
		<if @sections.available_slots@ not nil and @sections.available_slots@ gt 0>,<br />@sections.available_slots;noquote@ #dotlrn-ecommerce.available#</if>
		<if @sections.available_slots@ le 0>
		<br />#dotlrn-ecommerce.lt_This_section_is_curre#
		</if>
		</if>
		<if @sections.fs_chunk@ not nil>
		<br />
		@sections.fs_chunk;noquote@
		</if>


<!-- payment/register buttons -->

		<if @sections.section_id@ not nil>
		<p>
		<div style="float: left">
		<if @sections.prices@ ne "">
		<if @allow_other_registration_p;literal@ true>
		<if @offer_code_p;literal@ true and @sections.has_discount_p@ and @sections.available_slots@ gt 0>

		<if @sections.assessment_id@ eq "" or @sections.assessment_id@ eq -1>

		<form action="ecommerce/offer-code-set">
		<input type="hidden" name="product_id" value="@sections.product_id@" />
		<input type="hidden" name="return_url" value="@sections.shopping_cart_add_url@" />
		[_ dotlrn-ecommerce.Offer_Code] <input name="offer_code" size="10" /><br />
		<input type="submit" value="@sections.button@" />
		</form>		

		</if>
		<else>
		<a href="@sections.shopping_cart_add_url;noquote@" class="button">@sections.button@</a>
		</else>
		</if>
		<else>
		<a href="@sections.shopping_cart_add_url;noquote@" class="button">@sections.button@</a>
		</else>
		</if>
		<else>
                <if @sections.member_p@ ne 1 and @sections.pending_p@ ne 1 and @sections.waiting_p@ ne 1 and @sections.waiting_p@ ne 2 and @sections.approved_p@ ne 1>
		<if @offer_code_p;literal@ true and @sections.has_discount_p@ and @sections.available_slots@ gt 0>

		<if @sections.assessment_id@ eq "" or @sections.assessment_id@ eq -1>

		<form action="ecommerce/offer-code-set">
		<input type="hidden" name="product_id" value="@sections.product_id@" />
		<input type="hidden" name="return_url" value="@sections.shopping_cart_add_url@" />
		[_ dotlrn-ecommerce.Offer_Code] <input name="offer_code" size="10" /><br />
		<input type="submit" value="@sections.button@" />
		</form>		

		</if>
		<else>
		<a href="@sections.shopping_cart_add_url;noquote@" class="button">@sections.button@</a>
		</else>
		</if>
		<else>
		<a href="@sections.shopping_cart_add_url;noquote@" class="button">@sections.button@</a>
		</else>
		</if>
		</else>
		</if>
		<if @sections.prices@ eq "">
		<a href="@sections.shopping_cart_add_url;noquote@" class="button">[_ dotlrn-ecommerce.register]</a>
		</if>
		
		<if @sections.pending_p;literal@ true>
		   <font color="red">[_ dotlrn-ecommerce.application_pending]</font>
		</if>
		<if @sections.waiting_p;literal@ true>
		   <font color="red">[_ dotlrn-ecommerce.lt_You_are_number_course]</font>
		</if>
		<if @sections.asm_url@ not nil>
		@sections.asm_url;noquote@
		</if>
		<if @sections.waiting_p@ eq 2 and @sections.asm_url@ nil>
		<font color="red">[_ dotlrn-ecommerce.awaiting_approval]</font>
		</if>
		<if @sections.instructor_p@ ne -1>
		  <a href="applications" class="button">[_ dotlrn-ecommerce.view_applications]</a>
		</if>
		</div>

		<if @sections.approved_p;literal@ true>
		<div align="center" style="float: right">
		
  		   <if @sections.member_state@ eq "request approved">
		   [_ dotlrn-ecommerce.lt_Your_application_was_]<p />
		   </if>
		   <else>
		   [_ dotlrn-ecommerce.lt_A_place_is_now_availa]<p />
		   </else>

		<if @offer_code_p;literal@ true and @sections.has_discount_p;literal@ true>
		<p />
		<form action="ecommerce/offer-code-set">
		<input type="hidden" name="product_id" value="@sections.product_id@" />
		<input type="hidden" name="return_url" value="@sections.shopping_cart_add_url@" />
		[_ dotlrn-ecommerce.Offer_Code] <input name="offer_code" size="10" /><br />
		<input type="submit" value="[_ dotlrn-ecommerce.lt_Continue_Registration]" />
		</form>
		</if>
		<else>
		<a href="@sections.registration_approved_url;noquote@" class="button">[_ dotlrn-ecommerce.lt_Continue_Registration]</a>
		</else>
		</div>
		</if>
		</p>
		</if>
		
		<div align="center" style="float: right">
		@sections.patron_message;noquote@
		</div>
<!-- end buttons -->
</div>
</multiple>
</div>