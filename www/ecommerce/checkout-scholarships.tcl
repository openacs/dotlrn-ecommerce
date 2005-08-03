# packages/dotlrn-ecommerce/www/ecommerce/checkout-scholarships.tcl

ad_page_contract {
    
    Purchase via scholarships
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-02
    @arch-tag: 04002975-c572-48b8-8003-fa134bcc82d4
    @cvs-id $Id$
} {
    return_url:notnull
    user_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

template::list::create \
    -key fund_id \
    -name scholarships \
    -multirow scholarships \
    -bulk_actions {Purchase checkout-scholarships-2 Purchase} \
    -bulk_action_export_vars { user_id return_url } \
    -elements {
        title { label "Title" }
        description { label "Description" }
	amount { label "Amount in Fund" }
	grant_amount {
	    label "Amount to Grant"
	    display_template {
		<input name="amount.@scholarships.fund_id@" size="10" />
	    }
	}
    }

db_multirow scholarships scholarships {
    select sf.*
    from scholarship_fundi sf,
    cr_items ci
    where sf.revision_id = ci.live_revision
} {
}