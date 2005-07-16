# packages/dotlrn-ecommerce/lib/categorized-products.tcl
#
# shows products listed under a category (ec_subcategories)
#
# @author Deds Castillo (deds@i-manila.com.ph)
# @creation-date 2005-07-12
# @arch-tag: 64c6a9f0-60d8-4adf-a7d8-3cda53ed6b68
# @cvs-id $Id$

foreach required_param {category_id} {
    if {![info exists $required_param]} {
        return -code error "$required_param is a required parameter."
    }
}

foreach optional_param {user_id restrict_to_one_p participant_id} {
    if {![info exists $optional_param]} {
        set $optional_param {}
    }
}

if {[empty_string_p $user_id]} {
    set user_id [ad_conn user_id]
}

if {[empty_string_p $participant_id] || [string equal $participant_id 0]} {
    set participant_id $user_id
}

if {[empty_string_p $restrict_to_one_p]} {
    set restrict_to_one_p 0
}

template::list::create \
    -name products \
    -multirow products \
    -elements {
        product_name {
            label "Product name"
        } 
        one_line_description {
            label "Description"
        }
        pretty_price {
            label "Price"
        }
        actions {
            label ""
            display_template {
                <a href="@products.shopping_cart_add_url;noquote@" class="button">Add to cart</a>
            }
        }
    }

set in_basket_where ""
if {$restrict_to_one_p} {
    set user_session_id [ec_get_user_session_id]
    ec_create_new_session_if_necessary [export_url_vars user_id]

    set in_basket_p [db_string get_in_basket {
	select count(*)
	from ec_orders o,
	     ec_items i,
	     ec_category_product_map m
	where o.user_session_id = :user_session_id
	      and o.order_id = i.order_id
	      and i.product_id = m.product_id
	      and m.category_id = :category_id
    }]
    if {$in_basket_p} {
	append in_basket_where " and 0=1"
    }
} 

set currency [ad_parameter -package_id [ec_id] Currency ecommerce]

db_multirow -extend { pretty_price shopping_cart_add_url } products products "
    select p.product_id,
           p.product_name,
           p.one_line_description,
           p.price
    from ec_products p,
         ec_category_product_map m
    where m.category_id = :category_id
          and m.product_id = p.product_id
          $in_basket_where
" {
    set pretty_price [ec_pretty_price $price $currency]
    set shopping_cart_add_url [export_vars -base shopping-cart-add { user_id participant_id product_id }]
}
