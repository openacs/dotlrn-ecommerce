<master>
  <property name="title">Your Shopping Cart</property>
  <property name="context">@context;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

  <property name="show_toolbar_p">t</property>
  <property name="current_location">shopping-cart</property>

  <if @user_id@ ne 0>
    <if @admin_p;literal@ true>
	You are processing an order for @first_names@ @last_name@. (To change the purchaser,  
    </if>
    <else>	
    #dotlrn-ecommerce.lt_for_first_names_last_#,
    </else>
    <a href="<if @admin_p;literal@ true>../admin/process-purchase-all</if><else>../</else>">#dotlrn-ecommerce.click_here#</a>)
  </if>

<if @suppress_membership_p@ ne 1>
  <br />
  <a href="memberships?user_id=@user_id@">Buy a membership now and save on your course purchases.</a><br />
  Are you already a member? <a href="member-validate?user_id=@user_id@">Enter your member id now</a>
</if>

  <blockquote>
    <multiple name="in_cart">
      <if @in_cart.rownum@ eq 1>
	  <table border="0" cellspacing="0" cellpadding="5" align="center">
	    <tr bgcolor="#cccccc">
	      <td>#dotlrn-ecommerce.Item_Description#</td>
	      <if @user_id@ ne 0>
		<td>#dotlrn-ecommerce.Paid_By#</td>
		<td>#dotlrn-ecommerce.Participant#</td>
	      </if>
	      <td>#dotlrn-ecommerce.Quantity#</td>
	      <td>#dotlrn-ecommerce.PriceItem#</td>
	      <if @product_counter@ gt 1> <td>#dotlrn-ecommerce.Subtotal_1#</td> </if>
	      <if @offer_code_p@ gt 1>
		<td>#dotlrn-ecommerce.Discount#</td>
	      </if>
	      <td>#dotlrn-ecommerce.Action#</td>
	    </tr>
      </if>
      <tr>
	<td>
	  @in_cart.product_name@
	</td>
	<if @user_id@ ne 0>
	  <if @in_cart.patron_id@ eq @in_cart.participant_id@>
	    <td>
	      @in_cart.patron_name@
	    </td>
	    <td>
	      <if @in_cart.section_id@ not nil>#dotlrn-ecommerce.lt_Participant_pays_for_#</if>
	      <else>&nbsp;</else>
	    </td>
	  </if>
	  <else>
	    <td>
	      @in_cart.patron_name@
	    </td>
	    <td>
	      <if @in_cart.participant_type@ eq "group">
		Group: @in_cart.participant_name@
	      </if>
	      <else>
		@in_cart.participant_name@
	      </else>
	    </td>
	  </else>
	</if>
	<td align=center>
	  @in_cart.quantity@
	</td>
	<td>@in_cart.price;noquote@</td>
	<if @product_counter@ gt 1><td align="right">@in_cart.line_subtotal;noquote@</td>
	</if>
	<if @in_cart.has_discount_p;literal@ true>
	  <td nowrap>
	    <form method=post action=offer-code-set>
	      <input type="hidden" name="user_id" value="@user_id@" />
	      <input type="hidden" name="product_id" value="@in_cart.product_id@" />
	      <input type="hidden" name="return_url" value="shopping-cart?user_id=@user_id@" />
	      <input name="offer_code" size="10" /><input type="submit" value="#dotlrn-ecommerce.Enter_Offer_Code#" />
	    </form>
	  </td>
	</if>
	<else>
	  <if @offer_code_p@ gt 1><td></td></if>
	</else>
	<td>
	  <a href="shopping-cart-delete-from?@in_cart.delete_export_vars@">#dotlrn-ecommerce.delete#</a>
	</td>
      </tr>
    </multiple>
    
    <if @product_counter@ ne 0>
      <tr bgcolor="#cccccc">
	<td <if @user_id@ ne 0>colspan="3" </if>align="right">#dotlrn-ecommerce.Total#</td>
	<td align=center>@product_counter@</td>
	<if @product_counter@ gt 1><td bgcolor="#cccccc">&nbsp;</td>
	</if>
	<td align="right">@pretty_total_price;noquote@</td>
	<td></td>
	<if @offer_code_p@ gt 1>
	  <td></td>
	</if>
      </tr>
      <if @shipping_gateway_in_use@ false>
	<if @no_shipping_options@ false>
	  <tr>
	    <if @product_counter@ gt 1>
	      <td colspan="4" align="right">
	    </if>
	    <else>
	      <td colspan="3" align="right">
	    </else>
	    @shipping_options@</td>
	    <td align="right">@total_reg_shipping_price@</td><td>standard</td>
	  </tr>

	  <if @offer_express_shipping_p;literal@ true>
	    <tr>
	      <if @product_counter@ gt 1>
		<td colspan="4">
	      </if>
	      <else>
		<td colspan="3">
	      </else>
	      &nbsp;</td>
	      <td align="right">@total_exp_shipping_price@</td><td>express</td>
	    </tr>
	  </if>

	  <if @offer_pickup_option_p;literal@ true>
	    <tr>
	      <if @product_counter@ gt 1>
		<td colspan="4">
	      </if>
	      <else>
		<td colspan="3">
	      </else>
	      &nbsp;
	    </td>
	      <td align="right">@shipping_method_pickup@</td><td>pickup</td>
	    </tr>
	  </if>
	</if>
      </if>


      <multiple name="tax_entries">
	<tr>
	  <td colspan="5">
	    Residents of @tax_entries.state@, please add @tax_entries.pretty_tax@ tax.
	  </td>
	</tr>
      </multiple>
    </table>

      <if @shipping_gateway_in_use@ true>
	@shipping_options;noquote@
      </if>

      <center>
	<form method=post action="checkout-one-form">
	  <input type="hidden" name="user_id" value="@user_id@" />
	  <input type=submit value="Proceed to Checkout"><br>
	</form>
      </center>
    </if>
    <else>
      <center>#dotlrn-ecommerce.lt_Your_Shopping_Cart_is#</center>
    </else>

    <ul>
<if @donation_category_id@ not nil>
      <li> <a href="donations?user_id=@user_id@">#dotlrn-ecommerce.Make_a_donation#</a> </li>
</if>
      <li> <a href="<if @admin_p;literal@ true and @user_id@ ne @viewing_user_id@>../admin/process-purchase-course?user_id=@user_id@</if><else>../</else>">#dotlrn-ecommerce.lt_Purchase__another_Cou#</a> </li>
    </ul>
  </blockquote>
