#!/bin/bash

if [ -z "$CRS_PATH" ]; then
    echo "Please set CRS_PATH env variable."
    exit 1
fi
python -c "import re;import os;out=re.sub('(#SecAction[\S\s]*id:900000[\s\S]*paranoia_level=1\")','SecAction \\\\\n  \"id:900000, \\\\\n   phase:1, \\\\\n   nolog, \\\\\n   pass, \\\\\n   t:none, \\\\\n   setvar:tx.paranoia_level='+os.environ['PARANOIA']+'\"',open(os.environ['CRS_PATH']+'/crs-setup.conf','r').read());open(os.environ['CRS_PATH']+'/crs-setup.conf','w').write(out)" && \
python -c "import re;import os;out=re.sub('(#SecAction[\S\s]*id:900330[\s\S]*total_arg_length=64000\")','SecAction \\\\\n \"id:900330, \\\\\n phase:1, \\\\\n nolog, \\\\\n pass, \\\\\n t:none, \\\\\n setvar:tx.total_arg_length=64000\"',open(os.environ['CRS_PATH']+'/crs-setup.conf','r').read());open(os.environ['CRS_PATH']+'/crs-setup.conf','w').write(out)" && \

if [ "${SEC_RULE_ENGINE}" != "" ]; then
  sed -i "s/SecRuleEngine On/SecRuleEngine ${SEC_RULE_ENGINE}/" /etc/nginx/nginx.conf
  echo "SecRuleEngine set to '${SEC_RULE_ENGINE}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT}" != "" ]; then
  sed -i "s/SecPcreMatchLimit 500000/SecPcreMatchLimit ${SEC_PRCE_MATCH_LIMIT}/" /etc/nginx/nginx.conf
  echo "SecPcreMatchLimit set to '${SEC_PRCE_MATCH_LIMIT}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT_RECURSION}" != "" ]; then
  sed -i "s/SecPcreMatchLimitRecursion 500000/SecPcreMatchLimitRecursion ${SEC_PRCE_MATCH_LIMIT_RECURSION}/" /etc/nginx/nginx.conf
  echo "SecPcreMatchLimitRecursion set to '${SEC_PRCE_MATCH_LIMIT_RECURSION}'"
fi

if [ "${PROXY_UPSTREAM_HOST}" != "" ]; then
  sed -i "s/127.0.0.1:3000/${PROXY_UPSTREAM_HOST}/g" /etc/nginx/nginx.conf
  echo "Upstream host set to '${PROXY_UPSTREAM_HOST}'"
fi

if [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "OFF" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "No" ]; then
  sed -i "s,add_header X-Frame-Options SAMEORIGIN;$,add_header X-Frame-Options ${PROXY_HEADER_X_FRAME_OPTIONS};,g" /etc/nginx/nginx.conf
  echo "X-Frame-Options set to '${PROXY_HEADER_X_FRAME_OPTIONS}'"
else
  sed -i "s/add_header X-Frame-Options SAMEORIGIN;$//g" /etc/nginx/nginx.conf
  echo "X-Frame-Options disabled"
fi

names=`env | grep SEC_RULE_BEFORE_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    sed -i "/SecPcreMatchLimitRecursion/a\      $value" /etc/nginx/nginx.conf
  done <<< "$names"
fi

names=`env | grep SEC_RULE_AFTER_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    sed -i "/SecPcreMatchLimitRecursion/a\      $value" /etc/nginx/nginx.conf
  done <<< "$names"
fi

cat /etc/nginx/nginx.conf

exec "$@"
