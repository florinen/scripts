#!/bin/bash 
set -x #uncomment for debugging

zone="omegnet.com"
Pub_prefix="add prefix"
Secret="add secret"
ionos_API_key="${Pub_prefix}.${Secret}"
hostig_dns="https://api.hosting.ionos.com/dns/v1/zones"
cname_record="${1}"

zone_id (){
  curl -X GET "https://api.hosting.ionos.com/dns/v1/zones" \
	-H  "X-API-Key: ${ionos_API_key}" \
	-H "accept: application/json" | yq -r '.[] | .id'
  }
url="${hostig_dns}/$(zone_id)"

record_id (){
  curl -X 'GET' \
  "${url}?suffix=${zone}&recordType=CNAME" \
  -H 'accept: application/json' \
  -H 'Content-type: application/json' \
  -H "X-API-Key: ${ionos_API_key}" | yq -r '.records[] | "\(.name) \(.id)"' |grep -w "${cname_record}" | cut -d' ' -f2 
  }

all_cnames (){
  curl -X 'GET' \
  "${url}?suffix=${zone}&recordType=CNAME" \
  -H 'accept: application/json' \
  -H 'Content-type: application/json' \
  -H "X-API-Key: ${ionos_API_key}" | yq -r '.records[] '
  }

update_cnames (){
  curl -X 'PUT' \
  "${url}/records/$(record_id)" \
  -H 'accept: application/json' \
  -H 'Content-type: application/json' \
  -H "X-API-Key: ${ionos_API_key}" \
  -d '{
    "name": "'"$cname_record.$zone"'",
    "type":"CNAME",
    "disabled": false,
    "content": "'"$zone"'",
    "ttl": 300,
    "prio": 0
    }'
  }
  # -d '{"name":"'"$cname_record.$zone"'","type":"CNAME","content":"'"$zone"'","ttl":300,"disabled":false}'

add_cname (){
  curl -X 'POST' \
  "${url}/records" \
  -H 'accept: application/json' \
  -H 'Content-type: application/json' \
  -H "X-API-Key: ${ionos_API_key}" \
  -d '[{"name":"'"$cname_record.$zone"'","type":"CNAME","content":"'"$zone"'","ttl":300,"disabled":false}]'
  }

del_cnames (){
  curl -X 'DELETE' \
  "${url}/records/$(record_id)" \
  -H 'accept: */*' \
  -H "X-API-Key: ${ionos_API_key}"
  }


# record_id
# all_cnames
update_cnames
# add_cname
# del_cnames



# cat <<EOF >$(pwd)/data.json 
# '[
#   {
#     "name": "$cname_record.$zone",
#     "type":"CNAME",
#     "disabled": false,
#     "content": "$zone",
#     "ttl": 180,
#     "prio": 0 
#   }
# ]'
# EOF
# JSONSTRING=[{"name":"$cname_record.$zone","type":"CNAME","content":"$zone","ttl":300,"disabled":false}]

# -d '[
#   {
#     \"name\": \"$cname_record.$zone\",
#     \"disabled\": false,
#     \"content\": \"$zone\",
#     \"ttl\": 180,
#     \"prio\": 0 
#   }
# ]'