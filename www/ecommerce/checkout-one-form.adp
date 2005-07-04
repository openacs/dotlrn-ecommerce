<master>

<!-- following from billing.adp -->

  <property name="title">Completing Your Order</property>

  <p>To complete your order, submit this form, and confirm the information
    on the following page.</p>

<if @more_addresses_available@ true>
  <p>Alternately, you can use a <a href="checkout">multi-page order process</a>, 
  if you prefer using some of your other addresses on file with us.
  </p>
</if>

<!-- shipping detail -->
<!--   from address.adp  -->
<p>1. Please review your order list for accuracy.</p>
<h3>Order list</h3>
 @items_ul;noquote@
<hr>
<p>2. Complete this information.</p>

<formtemplate id="checkout"></formtemplate>