<master>
  <property name="title">Your Shopping Cart</property>
  <property name="context">@context;noquote@</property>
  <property name="signatory">@ec_system_owner;noquote@</property>

  <property name="show_toolbar_p">t</property>
  <property name="current_location">shopping-cart</property>

<if @user_id@ ne 0>
  for @first_names@ @last_name@ (if you're not @first_names@ @last_name@, 
  <a href="<if @admin_p@>../admin/process-purchase-all</if><else>../</else>">click here</a>).
</if>

<blockquote>
  <multiple name="in_cart">
    <if @in_cart.rownum@ eq 1>
       <form method=post action=shopping-cart-quantities-change>

           <table border="0" cellspacing="0" cellpadding="5" align="center">
             <tr bgcolor="#cccccc">
               <td>Item Description</td>
	      <td>Paid By</td>
	      <td>Participant</td>
               <td>Quantity</td>
               <td>Price/Item</td>
<if @product_counter@ gt 1> <td>Subtotal</td> </if>
               <td>Action</td>
             </tr>
    </if>
    <tr>
      <td>
	  @in_cart.product_name@
      </td>
	<if @in_cart.patron_id@ eq @in_cart.participant_id@>
	  <td colspan=2 align=center>
	    @in_cart.patron_name@
	  </td>
	</if>
	<else>
	  <td>
	    @in_cart.patron_name@
	  </td>
	  <td>
	    <if @in_cart.participant_type@ eq "group">
	      Group: @group.group_name@
	    </if>
	    <else>
	      @in_cart.participant_name@
	    </else>
	  </td>
	</else>
      <td align=center>
	  @in_cart.quantity@
      </td>
      <td>@in_cart.price;noquote@</td>
<if @product_counter@ gt 1><td align="right">@in_cart.line_subtotal@</td>
</if>
      <td>
        <a href="shopping-cart-delete-from?@in_cart.delete_export_vars@">delete</a>
      </td>
    </tr>
  </multiple>
  
  <if @product_counter@ ne 0>
    <tr bgcolor="#cccccc">
      <td colspan="3" align="right">Total:</td>
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
    <center>Your Shopping Cart is empty.</center>
  </else>

  <ul>
      <li> <a
      href="<if @admin_p@>../admin/process-purchase-course?user_id=@user_id@</if><else>../</else>">Purchase
      another Course/Section</a> </li>
  </ul>
</blockquote>
