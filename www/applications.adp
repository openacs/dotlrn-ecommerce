<master>
  <property name="title">#dotlrn-ecommerce.lt_Waiting_List_and_Prer#</property>
  <property name="context">{#dotlrn-ecommerce.lt_Waiting_List_and_Prer#}</property>
  <property name="header_stuff">@header_stuff;noquote@</property>
  
  <script type="text/javascript">
    <!--
    var searchItems = new Array();

    @search_arr.search_js_array;noquote@
    //-->
  </script>


<listfilters-form name="applications" style="form-filters"></listfilters-form>

  <script type="text/javascript">
    <!--
    if (searchItems[document.forms.as_search.as_item_id.value] == 'section' || searchItems[document.forms.as_search.as_item_id.value] == 'assessment' || document.forms.as_search.as_item_id.selectedIndex == 0) {
    	if (typeof(document.forms.as_search.as_search) != "undefined" && typeof(document.forms.as_search.search) != "undefined" ) {
    		document.forms.as_search.as_search.disabled = true;
    		document.forms.as_search.search.disabled = true;
    	}
    }
    //-->
  </script>
  <p />
  
  <listtemplate name="applications"></listtemplate>
<a href="@summary_url@">View application summary statistics</a>