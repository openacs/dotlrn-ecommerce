<master>

<!-- following from billing.adp -->

  <property name="title">#dotlrn-ecommerce.lt_Completing_Your_Order_1#</property>

  <p>#dotlrn-ecommerce.lt_To_complete_your_orde#</p>

<if @more_addresses_available@ true>
  <p>#dotlrn-ecommerce.lt_Alternately_you_can_u# <a href="checkout">#dotlrn-ecommerce.lt_multi-page_order_proc#</a>, 
  #dotlrn-ecommerce.lt_if_you_prefer_using_s#
  </p>
</if>

<!-- shipping detail -->
<!--   from address.adp  -->
<p>#dotlrn-ecommerce.lt_1_Please_review_your_#</p>
<h3>#dotlrn-ecommerce.Order_list#</h3>
 @items_ul;noquote@

<if @scholarships:rowcount@ gt 0>
    <h3>#dotlrn-ecommerce.Scholarships#</h3>
    <multiple name="scholarships">
      @scholarships.title@; Amount Granted @scholarships.grant_amount@<br />
    </multiple>
</if>

<hr>
<p>#dotlrn-ecommerce.lt_2_Complete_this_infor#</p>

<formtemplate id="checkout"></formtemplate>