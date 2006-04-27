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
      <li>#dotlrn-ecommerce.Participants# @items.quantity;noquote@: @items.product_name;noquote@; @items.options;noquote@@items.price_name;noquote@: @items.price_charged;noquote@</li>
    </multiple>
  </ul>

  <table width="250 100">
    <tr>
      <td>#dotlrn-ecommerce.Subtotal#</td><td>@pretty_subtotal;noquote@</td>
    </tr>
    <tr>
      <td>#dotlrn-ecommerce.Tax#</td><td>@pretty_tax;noquote@</td>
    </tr>
    <tr>
      <td></td><td>------------</td>
    </tr>
    <if @gift_certificate@ gt 0>
      <tr>
	<td>#dotlrn-ecommerce.TOTAL#</td><td>@pretty_total;noquote@</td>
      </tr>
      <tr>
	<td>#dotlrn-ecommerce.Gift_Certificate#</td><td>-@pretty_gift_certificate;noquote@</td>
      </tr>
      <tr>
	<td></td><td>------------</td>
      </tr>
      <tr>
	<td>#dotlrn-ecommerce.Balance_due#</td><td>@pretty_balance;noquote@</td>
      </tr>
    </if>
    <else>
      <tr>
	<td>#dotlrn-ecommerce.TOTAL#</td><td>@pretty_total;noquote@</td>
      </tr>
    </else>
  </table>

<p />
#dotlrn-ecommerce.Paid_Via# @payment_method;noquote@