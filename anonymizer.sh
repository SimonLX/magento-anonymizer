#!/bin/bash
echo "*** This script is anonymizing a DB-dump of the LIVE-DB in the DEMO-Environment ***"

PATH_TO_ROOT=$1
if [[ "$PATH_TO_ROOT" == "" && -f "app/etc/local.xml" ]]; then
  PATH_TO_ROOT="."
fi
if [[ "$PATH_TO_ROOT" == "" ]]; then
  echo "Please specify the path to your Magento store"
  exit 1
fi
CONFIG=$PATH_TO_ROOT"/.anonymizer.cfg"

if [[ 1 < $# ]]; then
  if [[ "-c" == "$1" ]]; then
    PATH_TO_ROOT=$3
    CONFIG=$2
    if [[ ! -f $CONFIG ]]; then
      echo -e "\E[1;31mCaution: \E[0mConfiguration file $CONFIG does not exist, yet! You will be asked to create it after the anonymization run."
      echo "Do you want to continue (Y/n)?"; read CONTINUE;
      if [[ ! -z "$CONTINUE" && "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        exit;
      fi
    fi
  fi
fi


while [[ ! -f $PATH_TO_ROOT/app/etc/local.xml ]]; do
  echo "$PATH_TO_ROOT is no valid Magento root folder. Please enter the correct path:"
  read PATH_TO_ROOT
done

HOST=`grep host $PATH_TO_ROOT/app/etc/local.xml | grep CDATA | sed 's/ *<host>\(.*\)<\/host>/\1/' | sed 's/<!\[CDATA\[//' | sed 's/\]\]>//'`
USER=`grep username $PATH_TO_ROOT/app/etc/local.xml | grep CDATA | sed 's/ *<username>\(.*\)<\/username>/\1/' | sed 's/<!\[CDATA\[//' | sed 's/\]\]>//'`
PASS=`grep password $PATH_TO_ROOT/app/etc/local.xml | grep CDATA | sed 's/ *<password>\(.*\)<\/password>/\1/' | sed 's/<!\[CDATA\[//' | sed 's/\]\]>//'`
NAME=`grep dbname $PATH_TO_ROOT/app/etc/local.xml | grep CDATA | sed 's/ *<dbname>\(.*\)<\/dbname>/\1/' | sed 's/<!\[CDATA\[//' | sed 's/\]\]>//'`

if [[ -f "$CONFIG" ]]; then
  echo "Using configuration file $CONFIG"
  source "$CONFIG"
fi

if [[ -z "$DEV_IDENTIFIERS" ]]; then
  DEV_IDENTIFIERS=".*(dev|stage|staging|test|anonym).*"
fi
if [[ $NAME =~ $DEV_IDENTIFIERS ]]; then
    echo "We are on the TEST environment, everything is fine"
else
    echo ""
    echo "IT SEEMS THAT WE ARE ON THE PRODUCTION ENVIRONMENT!"
    echo ""
    echo "If you are sure, this is a test environment, please type 'test' to continue"
    read force
    if [[ "$force" != "test" ]]; then
        echo "Canceled"
        exit 2
    fi
fi

if [ "$PASS" = "" ]; then
    DBCALL="mysql -u$USER -h$HOST $NAME -e"
else
    DBCALL="mysql -u$USER -p$PASS -h$HOST $NAME -e"
fi

echo "* Step 1: Anonymize names and emails"

if [[ -z "$RESET_ADMIN_PASSWORDS" ]]; then
  echo "  Do you want me to reset admin user passwords (Y/n)?"; read RESET_ADMIN_PASSWORDS
fi
if [[ "$RESET_ADMIN_PASSWORDS" == "y" || "$RESET_ADMIN_PASSWORDS" == "Y" || -z "$RESET_ADMIN_PASSWORDS" ]]; then
  RESET_ADMIN_PASSWORDS="y"
  # admin user
  $DBCALL "UPDATE admin_user SET password=MD5(CONCAT(username,'123'))"
else
  RESET_ADMIN_PASSWORDS="n"
fi

if [[ -z "$RESET_API_PASSWORDS" ]]; then
  echo "  Do you want me to reset API user passwords (Y/n)?"; read RESET_API_PASSWORDS
fi
if [[  "$RESET_API_PASSWORDS" == "y" || "$RESET_API_PASSWORDS" == "Y" || -z "$RESET_API_PASSWORDS" ]]; then
  RESET_API_PASSWORDS="y"
  # api user
  $DBCALL "UPDATE api_user SET api_key=MD5(CONCAT(username,'123'))"
else
  RESET_API_PASSWORDS="n"
fi

if [[ -z "$ANONYMIZE" ]]; then
  echo "  Do you want me to drop all customers data from your database (1), only anonymize your database (2), or do nothing (0)?"; read ANONYMIZE
fi
if [[ "$ANONYMIZE" == "1" ]]; then
  $DBCALL "SET FOREIGN_KEY_CHECKS=0;
    TRUNCATE customer_entity;
    TRUNCATE customer_entity_datetime;
    TRUNCATE customer_entity_decimal;
    TRUNCATE customer_entity_int;
    TRUNCATE customer_entity_text;
    TRUNCATE customer_entity_varchar;
    TRUNCATE customer_address_entity;
    TRUNCATE customer_address_entity_datetime;
    TRUNCATE customer_address_entity_decimal;
    TRUNCATE customer_address_entity_int;
    TRUNCATE customer_address_entity_text;
    TRUNCATE customer_address_entity_varchar;
    TRUNCATE catalog_compare_item;
    TRUNCATE newsletter_queue;
    TRUNCATE newsletter_queue_link;
    TRUNCATE newsletter_subscriber;
    TRUNCATE newsletter_problem;
    TRUNCATE newsletter_queue_store_link;
    TRUNCATE catalogsearch_query;
    TRUNCATE catalogsearch_fulltext;
    TRUNCATE catalogsearch_result;
    TRUNCATE poll;
    TRUNCATE poll_answer;
    TRUNCATE poll_store;
    TRUNCATE poll_vote;
    TRUNCATE wishlist;
    TRUNCATE wishlist_item;
    TRUNCATE sales_billing_agreement;
    TRUNCATE sales_billing_agreement_order;
    TRUNCATE sales_flat_order;
    TRUNCATE sales_flat_order_address;
    TRUNCATE sales_flat_order_grid;
    TRUNCATE sales_flat_order_item;
    TRUNCATE sales_flat_order_payment;
    TRUNCATE sales_flat_order_status_history;
    TRUNCATE sales_flat_quote;
    TRUNCATE sales_flat_quote_address;
    TRUNCATE sales_flat_quote_address_item;
    TRUNCATE sales_flat_quote_item;
    TRUNCATE sales_flat_quote_item_option;
    TRUNCATE sales_flat_quote_payment;
    TRUNCATE sales_flat_quote_shipping_rate;
    TRUNCATE sales_flat_shipment;
    TRUNCATE sales_flat_shipment_comment;
    TRUNCATE sales_flat_shipment_grid;
    TRUNCATE sales_flat_shipment_item;
    TRUNCATE sales_flat_shipment_track;
    TRUNCATE sales_order_tax;
    TRUNCATE sales_flat_invoice;
    TRUNCATE sales_flat_invoice_comment;
    TRUNCATE sales_flat_invoice_grid;
    TRUNCATE sales_flat_invoice_item;
    TRUNCATE sales_flat_creditmemo;
    TRUNCATE sales_flat_creditmemo_comment;
    TRUNCATE sales_flat_creditmemo_grid;
    TRUNCATE sales_flat_creditmemo_item;
    TRUNCATE sales_payment_transaction;
    TRUNCATE sales_recurring_profile;
    TRUNCATE sales_recurring_profile_order;
    TRUNCATE downloadable_link_purchased;
    TRUNCATE downloadable_link_purchased_item;
    SET FOREIGN_KEY_CHECKS=1;"
elif [[ "$ANONYMIZE" == "2" ]]; then
  # customer address
  ENTITY_TYPE="customer_address"
  ATTR_CODE="firstname"
  $DBCALL "UPDATE customer_address_entity_varchar SET value=CONCAT('firstname_',entity_id) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"
  ATTR_CODE="lastname"
  $DBCALL "UPDATE customer_address_entity_varchar SET value=CONCAT('lastname_',entity_id) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"
  ATTR_CODE="telephone"
  $DBCALL "UPDATE customer_address_entity_varchar SET value=CONCAT('0341 12345',entity_id) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"
  ATTR_CODE="fax"
  $DBCALL "UPDATE customer_address_entity_varchar SET value=CONCAT('0171 12345',entity_id) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"
  ATTR_CODE="street"
  $DBCALL "UPDATE customer_address_entity_text SET value=CONCAT(entity_id,' test avenue') WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"

  # customer account data
  if [[ -z "$KEEP_EMAIL" ]]; then
    echo "  If you want to keep some users credentials, please enter corresponding email addresses quoted by '\"' separated by comma (default: none):"; read KEEP_EMAIL
  fi
  ERRORS_KEEP_MAIL=`echo "$KEEP_EMAIL" | grep -vP -e '(\"[^\"]+@[^\"]+\")(, ?(\"[^\"]+@[^\"]+\"))*'`
  if [[ ! -z "$ERRORS_KEEP_MAIL" && "$KEEP_EMAIL" != '"none"' ]]; then
    while [[ ! -z "$errors_keep_mail" ]]; do
      echo -e "\e[1;31minvalid input! \E[0mExample: \"foo@bar.com\",\"me@example.com\"."
      echo "  If you want to keep some users credentials, please enter corresponding email addresses quoted by '\"' separated by comma (default: none):"; read KEEP_EMAIL
      ERRORS_KEEP_MAIL=`echo "$KEEP_EMAIL" | grep -vP -e '(\"[^\"]+@[^\"]+\")(, ?(\"[^\"]+@[^\"]+\"))*'`
      if [[ -z "$KEEP_MAIL" ]]; then
        break
      fi
    done
    if [[ ! -z "$KEEP_EMAIL" ]]; then
      echo "  Keeping $KEEP_EMAIL"
    fi
  else
    KEEP_EMAIL='"none"'
  fi

  ENTITY_TYPE="customer"
  $DBCALL "UPDATE customer_entity SET email=CONCAT('dev_',entity_id,'@trash-mail.com') WHERE email NOT IN ($KEEP_EMAIL)"
  ATTR_CODE="firstname"
  $DBCALL "UPDATE customer_entity_varchar SET value=CONCAT('firstname_',entity_id) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"
  ATTR_CODE="lastname"
  $DBCALL "UPDATE customer_entity_varchar SET value=CONCAT('lastname_',entity_id) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE'))"
  ATTR_CODE="password_hash"
  $DBCALL "UPDATE customer_entity_varchar v SET value=MD5(CONCAT('dev_',entity_id,'@trash-mail.com')) WHERE attribute_id=(select attribute_id from eav_attribute where attribute_code='$ATTR_CODE' and entity_type_id=(select entity_type_id from eav_entity_type where entity_type_code='$ENTITY_TYPE')) AND (SELECT email FROM customer_entity e WHERE e.entity_id=v.entity_id AND email NOT IN ($KEEP_EMAIL))"

  # credit memo
  $DBCALL "UPDATE sales_flat_creditmemo_grid SET billing_name='Demo User'"

  # invoices
  $DBCALL "UPDATE sales_flat_invoice_grid SET billing_name='Demo User'"

  # shipments
  $DBCALL "UPDATE sales_flat_shipment_grid SET shipping_name='Demo User'"

  # quotes
  $DBCALL "UPDATE sales_flat_quote SET customer_email=CONCAT('dev_',entity_id,'@trash-mail.com'), customer_firstname='Demo', customer_lastname='User', customer_middlename='Dev', remote_ip='192.168.1.1', password_hash=NULL WHERE customer_email NOT IN ($KEEP_EMAIL)"
  $DBCALL "UPDATE sales_flat_quote_address SET firstname='Demo', lastname='User', company=NULL, telephone=CONCAT('0123-4567', address_id), street=CONCAT('Devstreet ',address_id), email=CONCAT('dev_',address_id,'@trash-mail.com')"

  # orders
  $DBCALL "UPDATE sales_flat_order SET customer_email=CONCAT('dev_',entity_id,'@trash-mail.com'), customer_firstname='Demo', customer_lastname='User', customer_middlename='Dev'"
  $DBCALL "UPDATE sales_flat_order_address SET email=CONCAT('dev_',entity_id,'@trash-mail.com'), firstname='Demo', lastname='User', company=NULL, telephone=CONCAT('0123-4567', entity_id), street=CONCAT('Devstreet ',entity_id)"
  $DBCALL "UPDATE sales_flat_order_grid SET shipping_name='Demo D. User', billing_name='Demo D. User'"

  # payments
  $DBCALL "UPDATE sales_flat_order_payment SET additional_data=NULL, additional_information=NULL"

  # newsletter
  $DBCALL "UPDATE newsletter_subscriber SET subscriber_email=CONCAT('dev_newsletter_',subscriber_id,'@trash-mail.com') WHERE subscriber_email NOT IN ($KEEP_EMAIL)"
fi

if [[ -z "$TRUNCATE_LOGS" ]]; then
  echo "  Do you want me to truncate log tables (Y/n)?"; read TRUNCATE_LOGS
fi
if [[  "$TRUNCATE_LOGS" == "y" || "$TRUNCATE_LOGS" == "Y" || -z "$TRUNCATE_LOGS" ]]; then
  TRUNCATE_LOGS="y"
  # truncate unrequired tables
  $DBCALL "TRUNCATE log_customer"
  $DBCALL "TRUNCATE log_quote"
  $DBCALL "TRUNCATE log_summary"
  $DBCALL "TRUNCATE log_summary_type"
  $DBCALL "TRUNCATE log_url"
  $DBCALL "TRUNCATE log_url_info"
  $DBCALL "TRUNCATE log_visitor"
  $DBCALL "TRUNCATE log_visitor_info"
  $DBCALL "TRUNCATE log_visitor_online"
  $DBCALL "TRUNCATE report_event"
  $DBCALL "TRUNCATE report_viewed_product_index"
  $DBCALL "TRUNCATE report_compared_product_index"
  $DBCALL "TRUNCATE catalog_compare_item"
else
  TRUNCATE_LOGS="n"
fi

echo "* Step 2: Mod Config."
# disable assets merging, google analytics and robots
if [[ -z "$DEMO_NOTICE" ]]; then
  echo "  Do you want me to enable demo notice (Y/n)?"; read DEMO_NOTICE
fi
if [[  "$DEMO_NOTICE" == "y" || "$DEMO_NOTICE" == "Y" || -z "$DEMO_NOTICE" ]]; then
  DEMO_NOTICE="y"
  $DBCALL "INSERT INTO core_config_data (path, value) VALUES ('design/head/demonotice', '1') ON DUPLICATE KEY UPDATE value = '1'"
else
  DEMO_NOTICE="n"
fi
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('dev/css/merge_css_files', '0') ON DUPLICATE KEY UPDATE value = '0'"
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('dev/js/merge_files', '0') ON DUPLICATE KEY UPDATE value = '0'"
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('google/analytics/active', '0') ON DUPLICATE KEY UPDATE value = '0'"
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('design/head/default_robots', 'NOINDEX,NOFOLLOW') ON DUPLICATE KEY UPDATE value = 'NOINDEX,NOFOLLOW'"

# set mail receivers
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('trans_email/ident_general/email', 'general-magento-dev@trash-mail.com') ON DUPLICATE KEY UPDATE value = 'general-magento-dev@trash-mail.com'"
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('trans_email/ident_support/email', 'support-magento-dev@trash-mail.com') ON DUPLICATE KEY UPDATE value = 'support-magento-dev@trash-mail.com'"
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('trans_email/ident_custom1/email', 'custom1-magento-dev@trash-mail.com') ON DUPLICATE KEY UPDATE value = 'custom1-magento-dev@trash-mail.com'"
$DBCALL "INSERT INTO core_config_data (path, value) VALUES ('trans_email/ident_custom2/email', 'custom2-magento-dev@trash-mail.com') ON DUPLICATE KEY UPDATE value = 'custom2-magento-dev@trash-mail.com'"

# set base urls
if [[ -z "$RESET_BASE_URLS" ]]; then
  echo "  Do you want to reset base urls (Y/n)?"; read RESET_BASE_URLS
fi
if [[ "$RESET_BASE_URLS" == "y" || "$RESET_BASE_URLS" == "Y" || -z "$RESET_BASE_URLS" ]]; then
  RESET_BASE_URLS="y"
  if [[ -z "$SPECIFIC_BASE_URLS" ]]; then
    echo "  Do you want to specify base urls explicitly (Y/n)?"; read SPECIFIC_BASE_URLS
  fi
  if [[ "$SPECIFIC_BASE_URLS" == "y" || "$SPECIFIC_BASE_URLS" == "Y" || -z "$SPECIFIC_BASE_URLS" ]]; then
    SPECIFIC_BASE_URLS="y"
    if [[ -z "$SCOPES" ]]; then
      SCOPES=()
      SCOPE_IDS=()
      BASE_URLS=()

      SCOPE_ID="(to be specified)"
      while [[ "$SCOPE_ID" != "" ]]; do
        echo "Enter scope id [Hit enter to finish]: "
        read SCOPE_ID
        if [[ "$SCOPE_ID" != "" ]]; then
          echo "Enter scope [stores]: "
          read SCOPE
          if [[ "$SCOPE" == "" ]]; then
            SCOPE="stores"
          fi
          echo "Enter base url (format: https://www.example.com/): "
          read BASE_URL

          SCOPES=("${SCOPES[@]}" $SCOPE)
          SCOPE_IDS=("${SCOPE_IDS[@]}" $SCOPE_ID)
          BASE_URLS=("${BASE_URLS[@]}" $BASE_URL)
        fi
      done
    else
      echo "using preconfigured scope base urls"
    fi

    for i in "${!SCOPES[@]}"; do
      SCOPE=${SCOPES[$i]}
      SCOPE_ID=${SCOPE_IDS[$i]}
      BASE_URL=${BASE_URLS[$i]}
      $DBCALL "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ($SCOPE_ID, $SCOPE, 'web/unsecure/base_url', '$BASE_URL') ON DUPLICATE KEY UPDATE value = '$BASE_URL'"
      $DBCALL "INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ($SCOPE_ID, $SCOPE, 'web/secure/base_url', '$BASE_URL') ON DUPLICATE KEY UPDATE value = '$BASE_URL'"
    done
  else
    SPECIFIC_BASE_URLS="n"
  fi
else
  RESET_BASE_URLS="n"
fi

# increase increment ids
## generate random number from 10 to 100
function genRandomChar() {

  factor=$RANDOM;
  min=65
  max=90
  let "factor %= $max-$min"
  let "factor += $min";

  printf \\$(printf '%03o' $(($factor)))
}
PREFIX="`genRandomChar``genRandomChar``genRandomChar`"
$DBCALL "UPDATE eav_entity_store SET increment_last_id=NULL, increment_prefix=CONCAT(store_id, '-', '$PREFIX', '-')"

# set test mode everywhere
$DBCALL "UPDATE core_config_data SET value='test' WHERE value LIKE 'live'"
$DBCALL "UPDATE core_config_data SET value='test' WHERE value LIKE 'prod'"
$DBCALL "UPDATE core_config_data SET value=1 WHERE path LIKE '%/testmode'"

# handle PAYONE config
PAYONE_TABLES=`$DBCALL "SHOW TABLES LIKE 'payone_config_payment_method'"`
if [ ! -z "$PAYONE_TABLES" ]; then
  echo "    * Mod PAYONE Config."
  $DBCALL "UPDATE payone_config_payment_method SET mode='test' WHERE mode='live'"
  if [[ -z "$PAYONE_MID" && -z "$PAYONE_PORTALID" && -z "$PAYONE_AID" && -z "$PAYONE_KEY" ]]; then
    echo -e "\E[1;31mCaution: \E[0mYou probably need to change portal IDs and keys for your staging/dev PAYONE payment methods!"
    echo "Please enter your testing/staging/dev merchant ID: "
    read PAYONE_MID
    echo "Please enter your testing/staging/dev portal ID: "
    read PAYONE_PORTALID
    echo "Please enter your testing/staging/dev sub account ID: "
    read PAYONE_AID
    echo "Please enter your testing/staging/dev security key: "
    read PAYONE_KEY
  fi

  $DBCALL "UPDATE core_config_data SET value='$PAYONE_MID' WHERE path='payone_general/global/mid'"
  $DBCALL "UPDATE core_config_data SET value='$PAYONE_PORTALID' WHERE path='payone_general/global/portalid'"
  $DBCALL "UPDATE core_config_data SET value='$PAYONE_AID' WHERE path='payone_general/global/aid'"
  $DBCALL "UPDATE core_config_data SET value='$PAYONE_KEY' WHERE path='payone_general/global/key'"

  $DBCALL "UPDATE payone_config_payment_method SET mid='$PAYONE_MID' WHERE mid IS NOT NULL"
  $DBCALL "UPDATE payone_config_payment_method SET portalid='$PAYONE_PORTALID' WHERE portalid IS NOT NULL"
  $DBCALL "UPDATE payone_config_payment_method SET aid='$PAYONE_AID' WHERE aid IS NOT NULL"
  $DBCALL "UPDATE payone_config_payment_method SET \`key\`='$PAYONE_KEY' WHERE \`key\` IS NOT NULL"
fi

echo "Done."

if [[ ! -f $CONFIG ]]; then
  echo "Do you want to create an anonymizer configuration file based on your answers (Y/n)?"; read CREATE
  if [[  "$CREATE" == "y" || "$CREATE" == "Y" || -z "$CREATE" ]]; then
    echo "DEV_IDENTIFIERS=$DEV_IDENTIFIERS">>$CONFIG
    echo "RESET_ADMIN_PASSWORDS=$RESET_ADMIN_PASSWORDS">>$CONFIG
    echo "RESET_API_PASSWORDS=$RESET_API_PASSWORDS">>$CONFIG
    echo "KEEP_EMAIL=$KEEP_EMAIL">>$CONFIG
    echo "ANONYMIZE=$ANONYMIZE">>$CONFIG
    echo "TRUNCATE_LOGS=$TRUNCATE_LOGS">>$CONFIG
    echo "DEMO_NOTICE=$DEMO_NOTICE">>$CONFIG
    if [ ! -z "$PAYONE_TABLES" ]; then
      echo "PAYONE_MID=$PAYONE_MID">>$CONFIG
      echo "PAYONE_PORTALID=$PAYONE_PORTALID">>$CONFIG
      echo "PAYONE_AID=$PAYONE_AID">>$CONFIG
      echo "PAYONE_KEY=$PAYONE_KEY">>$CONFIG
    fi
    echo "RESET_BASE_URLS=$RESET_BASE_URLS">>$CONFIG
    echo "SPECIFIC_BASE_URLS=$SPECIFIC_BASE_URLS">>$CONFIG
    if [[ ! -z $SCOPES ]]; then
      echo "SCOPES=(${SCOPES[@]})">>$CONFIG
      echo "SCOPE_IDS=(${SCOPE_IDS[@]})">>$CONFIG
      echo "BASE_URLS=(${BASE_URLS[@]})">>$CONFIG
    fi
  fi
fi
