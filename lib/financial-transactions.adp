  <if @method@ eq "invoice">
    <blockquote>

      This order was <if @scholarship_p;literal@ true><b>partially</b> </if>paid by <b>invoice</b>.
      
      <ul>
	<b>Payments</b>
	<multiple name="invoice_payments">
	  <li>Date: @invoice_payments.pretty_payment_date@, Amount: @invoice_payments.amount;noquote@, Via: @invoice_payments.invoice_method@</li>
	</multiple>

	<if @invoice_payment_sum@ lt 0.01>
	  <li>No payments have been made</li>
	</if>
	
	<if @invoice_payment_sum@ lt @total_price@>
	  <li><a href="invoice-payment?order_id=@order_id@">Add Payment</a></li>
	</if>
	
      </ul>
      
      TOTAL: <%=[ec_pretty_price $total_price]%>
      <br />
      Balance: <%=[ec_pretty_price [expr $total_price - $invoice_payment_sum + $total_refunds]]%>
    </blockquote>
  </if>
  
  <if @method@ eq "scholarship">
    <if @scholarship_p;literal@ true>
    <if @gc_amount@ eq @total_price@>
      <blockquote>This order was <b>fully</b> paid by <b>scholarship</b>.
    </if>
    <else>
      <blockquote>This order was <b>partially</b> paid by <b>scholarship</b>.
    </else>
    
    <ul>
      <multiple name="funds">
	<li>Date: @funds.grant_date@, Fund: @funds.title@, Amount Granted: @funds.grant_amount;noquote@, Amount Used: @funds.amount_used@</li>
      </multiple>
    </ul>
  </blockquote>
    </if>
  </if>

  <if @method@ eq "cc">
    <if @scholarship_p;literal@ true>
      <blockquote>This order was <b>partially</b> paid by <b>credit card</b>.
    </if>
    <else>
      <blockquote>This order was <b>fully</b> paid by <b>credit card</b>.
    </else>
    <p />
  </if>

  <if @financial_transactions:rowcount@ gt 0>
    <table border>
      <tr>
	<th>ID</th>
	<th>Date</th>
	<th>Creditcard Last 4</th>
	<th>Amount</th>
	<th>Type</th>
	<th>To Be Captured</th> 
	<th>Auth Date</th>
	<th>Mark Date</th>
	<th>Refund Date</th>
	<th>Failed</th>
      </tr>
      
      <multiple name="financial_transactions">
	<tr>
	  <td>@financial_transactions.transaction_id;noquote@</td>
	  <td>@financial_transactions.inserted_date;noquote@</td>
	  <td>@financial_transactions.creditcard_last_four;noquote@</td>
	  <td>@financial_transactions.transaction_amount;noquote@</td>
	  <td>@financial_transactions.transaction_type;noquote@</td>
	  <td>@financial_transactions.to_be_captured_p;noquote@</td>
	  <td>@financial_transactions.authorized_date;noquote@</td>
	  <td>@financial_transactions.marked_date;noquote@</td>
	  <td>@financial_transactions.refunded_date;noquote@</td>
	  <td>@financial_transactions.failed_p;noquote@</td>
	</tr>
      </multiple>
    </table>
  </if>
  <else>
    <if @method@ in "cash" "lockbox" "check">
      <blockquote>This order was <b><if @scholarship_p;literal@ true>partially</if><else>fully</else></b> paid by <b>check</b>.</blockquote>
    </if>
    <if @method@ eq "cc">
      <blockquote>No credit card transactions</blockquote>
    </if>
  </else>
