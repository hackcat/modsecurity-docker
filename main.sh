#!/bin/bash

set -e

if [ -z "$CRS_PATH" ]; then
    echo "Please set CRS_PATH env variable."
    exit 1
fi
python -c "import re;import os;out=re.sub('(#SecAction[\S\s]*id:900000[\s\S]*paranoia_level=1\")','SecAction \\\\\n  \"id:900000, \\\\\n   phase:1, \\\\\n   nolog, \\\\\n   pass, \\\\\n   t:none, \\\\\n   setvar:tx.paranoia_level='+os.environ['PARANOIA']+'\"',open(os.environ['CRS_PATH']+'/crs-setup.conf','r').read());open(os.environ['CRS_PATH']+'/crs-setup.conf','w').write(out)"
python -c "import re;import os;out=re.sub('(#SecAction[\S\s]*id:900330[\s\S]*total_arg_length=64000\")','SecAction \\\\\n \"id:900330, \\\\\n phase:1, \\\\\n nolog, \\\\\n pass, \\\\\n t:none, \\\\\n setvar:tx.total_arg_length=64000\"',open(os.environ['CRS_PATH']+'/crs-setup.conf','r').read());open(os.environ['CRS_PATH']+'/crs-setup.conf','w').write(out)"
echo "PARANOIA set to '${PARANOIA}'"

if [ "${SEC_RULE_ENGINE}" != "" ]; then
  sed -i".bak" "s/SecRuleEngine On/SecRuleEngine ${SEC_RULE_ENGINE}/" /etc/nginx/modsecurity.d/modsecurity.conf
  echo "SecRuleEngine set to '${SEC_RULE_ENGINE}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT}" != "" ]; then
  sed -i".bak" "s/SecPcreMatchLimit 1000/SecPcreMatchLimit ${SEC_PRCE_MATCH_LIMIT}/" /etc/nginx/modsecurity.d/modsecurity.conf
  echo "SecPcreMatchLimit set to '${SEC_PRCE_MATCH_LIMIT}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT_RECURSION}" != "" ]; then
  sed -i".bak" "s/SecPcreMatchLimitRecursion 1000/SecPcreMatchLimitRecursion ${SEC_PRCE_MATCH_LIMIT_RECURSION}/" /etc/nginx/modsecurity.d/modsecurity.conf
  echo "SecPcreMatchLimitRecursion set to '${SEC_PRCE_MATCH_LIMIT_RECURSION}'"
fi

if [ "${PROXY_UPSTREAM_HOST}" != "" ]; then
  sed -i "s/127.0.0.1:3000/${PROXY_UPSTREAM_HOST}/g" /etc/nginx/nginx.conf
  echo "Upstream host set to '${PROXY_UPSTREAM_HOST}'"
fi

if [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "Off" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "OFF" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "No" ] && [ "${PROXY_HEADER_X_FRAME_OPTIONS}" != "NO" ]; then
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
    echo "${value}" >> /etc/nginx/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
  done <<< "$names"
  echo "REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf"
  cat /etc/nginx/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
fi

names=`env | grep SEC_RULE_AFTER_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/nginx/modsecurity.d/owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
  done <<< "$names"
  echo "RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf"
  cat /etc/nginx/modsecurity.d/owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
fi

echo "Starting nginx"
exec "$@"
