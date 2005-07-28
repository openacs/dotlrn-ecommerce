<formtemplate id="register"></formtemplate>

<if @allow_no_email_p@ eq 1 and @user_type@ eq "purchaser">
  <script type="text/javascript">
    <!--
    if (document.register.no_email_p.checked == true) {
    document.register.email.disabled = 1;
    }
    //-->
  </script>
</if>