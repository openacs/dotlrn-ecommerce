#dotlrn-ecommerce.E-mail_address#<br />
  @email@
  <p />
  #dotlrn-ecommerce.Bill_to#
  @billing_address;noquote@<br />
  <if @creditcard_summary@ not nil>
    @creditcard_summary;noquote@
  </if>
  <p />
  #dotlrn-ecommerce.Courses#
  
  <ul>
    <multiple name="items">
      <li>#dotlrn-ecommerce.Participants# @items.quantity@: @items.product_name@; @items.options@@items.price_name@: @items.price_charged@</li>
    </multiple>
  </ul>

  <table width="250 100">
    <tr>
      <td>#dotlrn-ecommerce.Subtotal#</td><td>@subtotal@</td>
    </tr>
    <tr>
      <td>#dotlrn-ecommerce.Tax#</td><td>@tax@</td>
    </tr>
    <tr>
      <td></td><td>------------</td>
    </tr>
    <if @gift_certificate@ gt 0>
      <tr>
	<td>#dotlrn-ecommerce.TOTAL#</td><td>@total@</td>
      </tr>
      <tr>
	<td>#dotlrn-ecommerce.Gift_Certificate#</td><td>-@gift_certifcate@</td>
      </tr>
      <tr>
	<td></td><td>------------</td>
      </tr>
      <tr>
	<td>#dotlrn-ecommerce.Balance_due#</td><td>-@balance@</td>
      </tr>
    </if>
    <else>
      <tr>
	<td>#dotlrn-ecommerce.TOTAL#</td><td>@total@</td>
      </tr>
    </else>
  </table>
