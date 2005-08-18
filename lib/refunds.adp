  <h3>Refunds</h3>
  
  <blockquote>
    
    <if @refunds:rowcount@ gt 0>
      <multiple name="refunds">
	<group column="refund_id">
	  <if @refunds.rownum@ gt 1>
	    </ul>
	  </if>
	  Refund ID: @refunds.refund_id@<br />
	  Date: @refunds.refund_date@<br />
	  Amount: @refunds.refund_amount@<br />
	  Refunded by: @refunds.first_names@ @refunds.last_name@<br />
	  Reason: @refunds.refund_reasons@
	  <ul>
	</group>
	
	<li>Quantity @refunds.quantity@: @refunds.product_name@</li>
      </multiple>
    </ul>
    </if>
    <else>
      No Refunds Have Been Made
    </else>
    
  </blockquote>

