<master>
  <property name="title">Your Shopping Cart</property>
  <property name="context">@context;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

  <property name="show_toolbar_p">t</property>
  <property name="current_location">shopping-cart</property>

  <if @user_id@ ne 0>
    #dotlrn-ecommerce.lt_for_first_names_last_#,
    <a href="<if @admin_p@>../admin/process-purchase-all</if><else>../</else>">#dotlrn-ecommerce.click_here#</a>)
  </if>

  <blockquote>
    <multiple name="in_cart">
      <if @in_cart.rownum@ eq 1>
	<form method=post action=shopping-cart-quantities-change>

	  <table border="0" cellspacing="0" cellpadding="5" align="center">
	    <tr bgcolor="#cccccc">
	      <td>#dotlrn-ecommerce.Item_Description#</td>
	      <td>#dotlrn-ecommerce.Paid_By#</td>
	      <td>#dotlrn-ecommerce.Participant#</td>
	      <td>#dotlrn-ecommerce.Quantity#</td>
	      <td>#dotlrn-ecommerce.PriceItem#</td>
	      <if @product_counter@ gt 1> <td>#dotlrn-ecommerce.Subtotal_1#</td> </if>
	      <td>#dotlrn-ecommerce.Action#</td>
	    </tr>
      </if>
      <tr>
	<td>
	  @in_cart.product_name@
	</td>
	<if @in_cart.patron_id@ eq @in_cart.participant_id@>
	  <td>
	    @in_cart.patron_name@
	  </td>
	  <td>
	    #dotlrn-ecommerce.lt_Participant_pays_for_# (<a href="participant-change?item_id=@in_cart.item_id@">#dotlrn-ecommerce.change#</a>)
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
	    (<a href="participant-change?item_id=@in_cart.item_id@">#dotlrn-ecommerce.change#</a>)
	  </td>
	</else>
	<td align=center>
	  @in_cart.quantity@
	</td>
	<td>@in_cart.price;noquote@</td>
	<if @product_counter@ gt 1><td align="right">@in_cart.line_subtotal@</td>
	</if>
	<td>
	  <a href="shopping-cart-delete-from?@in_cart.delete_export_vars@">#dotlrn-ecommerce.delete#</a>
	  <if @admin_p@ and 0>DISABLED FOR NOW
	    <a href="@in_cart.edit_url;noquote@">#dotlrn-ecommerce.change#</a>
	  </if>
	</td>
      </tr>
    </multiple>
    
    <if @product_counter@ ne 0>
      <tr bgcolor="#cccccc">
	<td colspan="3" align="right">#dotlrn-ecommerce.Total#</td>
	<td align=center>@product_counter@</td>
	<if @product_counter@ gt 1><td bgcolor="#cccccc">&nbsp;</td>
	</if>
	<td align="right">@pretty_total_price@</td>
	<td></td>
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

	  <if @offer_express_shipping_p@ true>
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

	  <if @offer_pickup_option_p@ true>
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
    </form>

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
      <li> <a
	  href="<if @admin_p@>../admin/process-purchase-course?user_id=@user_id@</if><else>../</else>">#dotlrn-ecommerce.lt_Purchase__another_Cou#</a> </li>
    </ul>
  </blockquote>
