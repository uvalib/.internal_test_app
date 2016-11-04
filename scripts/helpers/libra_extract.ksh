#
# Scrip to extract data from legacy Libra
#

EXTRACT_DIR=tmp/extract
ITEM_TYPES="file_asset 4th_year_thesis master_thesis doctoral_thesis jefferson_trust"
ITEM_TYPES="file_asset 4th_year_thesis"

# other attributes
MAX_RECORDS=9999

#
# check status and error out if non-zero
#
function bomb_if_error {

   local res=$1
   if [ $res -ne 0 ]; then
      echo "ERROR $res, aborting"
      exit $res
   fi
}

#
# pull JSON from SOLR based on a series of query files
#
function solr_extract {

   # extract assets from SOLR
   for item in $ITEM_TYPES; do

      echo "****************************************"
      echo "Extracting $item records..."
      echo "****************************************"

      QUERY=data/solr_query/${item}_solr_query.txt
      RESULTS=$EXTRACT_DIR/${item}
      bundle exec rake libra2:extract:solr_extract $RESULTS $QUERY $MAX_RECORDS
      res=$?
      bomb_if_error $res
   done
}

#
# go through the SOLR records and add any file assets we can determine belong
#
function asset_extract {

   # process SOLR records and get extract assets
   for item in $ITEM_TYPES; do

      if [ "$item" == "file_asset" ]; then
         continue
      fi

      echo "****************************************"
      echo "Extracting $item assets..."
      echo "****************************************"

      ASSET_RECORDS=$EXTRACT_DIR/file_asset
      ITEM_RECORDS=$EXTRACT_DIR/${item}

      bundle exec rake libra2:extract:asset_extract $ITEM_RECORDS $ASSET_RECORDS
      res=$?
      bomb_if_error $res
   done
}

# pull necessary items from SOLR
#solr_extract

# mix in the file assets
asset_extract

# all over
exit 0
