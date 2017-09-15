<master>
  <property name="title">#dotlrn-ecommerce.Bulk_Payments#</property>

  <if @applications_registered:rowcount@ not defined>

    <formtemplate id="applications">
      <formwidget id="return_url" />

      <table border=0 cellpadding=2 cellspacing=2>
	<tr class="form-section"><th colspan="2">#dotlrn-ecommerce.Payment_Information#</th></tr>
	
	<tr class="form-element">

	  <td class="form-label">
	    
	    #dotlrn-ecommerce.lt_Select_a_payment_meth#
	    <span class="form-required-mark">*</span>
	    
	  </td>
	  
	  <td class="form-widget">
	    
	    <table class="formgroup">
	      <formgroup id="method">
		<tr>
		  <td>
		    @formgroup.widget;noquote@
		  </td>
		  <td class="form-widget">
		    <label for="applications:elements:method:@formgroup.option@">
		      @formgroup.label;noquote@
		    </label>
		  </td>
		</tr>
	      </formgroup>
	    </table>	    

	    <formerror id="method">
	      <div class="form-error">
		@formerror.method;noquote@
	      </div>
	    </formerror>

	  </td>
	</tr>

	<if @internal_account_p;literal@ true>
	  <tr class="form-element">
	    
	    <td class="form-label">
	      
	      #dotlrn-ecommerce.Internal_Account#
	      
	    </td>
	    
	    <td class="form-widget">
	      <formwidget id="internal_account" />
	      <formerror id="internal_account">
		<div class="form-error">
		  @formerror.internal_account;noquote@
		</div>
	      </formerror>	      
	    </td>
	  </tr>
	</if>

      </table>

      <p />

      <listtemplate name="applications"></listtemplate>
      
      <multiple name="applications">
	<input type="hidden" name="rel_id" value="@applications.rel_id@" />
      </multiple>
      
      <formwidget id="back" />
      <formwidget id="submit" />
    </formtemplate>

  </if>
  <else>
    <listtemplate name="applications_registered"></listtemplate>
  </else>

  <if @registered_exists_p;literal@ true>
    <p />
    <h3>#dotlrn-ecommerce.lt_The_following_users_p#</h3>
    <p />
    <listtemplate name="already_registered"></listtemplate>
  </if>
