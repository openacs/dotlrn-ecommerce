<formtemplate id="add_section"></formtemplate>

<if @adult_category_id@ defined and @submitted_p@ eq 0>
  <script type="text/javascript">
    <!--
    for (var i=0; i< document.add_section.categories.length; i++) {
    document.add_section.categories[i].value = '@adult_category_id@';
    }
    //-->
  </script>
</if>