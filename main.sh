#!/bin/bash

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
    echo "${value}" >> /etc/nginx/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
  done <<< "$names"
fi
echo "REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf"
cat /etc/nginx/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf

names=`env | grep SEC_RULE_AFTER_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/nginx/modsecurity.d/owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
  done <<< "$names"
fi
echo "RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf"
cat /etc/nginx/modsecurity.d/owasp-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

echo "Starting httpd"
exec "$@"
