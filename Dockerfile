# See following page to find out CRS version
# https://github.com/SpiderLabs/owasp-modsecurity-crs/blob/v3.0/master/CHANGES
#
# docker build -t fareoffice/modsecurity:<CRS-VERSION> .
# docker push fareoffice/modsecurity:<CRS-VERSION>

FROM owasp/modsecurity:v3-ubuntu-nginx

ENV PARANOIA=1
ENV CRS_PATH=/etc/nginx/modsecurity.d/owasp-crs

RUN apt-get update && \
    apt-get -y install python git ca-certificates

RUN cd /opt && \
  git clone -b v3.0/master --single-branch https://github.com/SpiderLabs/owasp-modsecurity-crs && \
  cd owasp-modsecurity-crs && \
  # 3.0.2
  git checkout e4e0497be4d598cce0e0a8fef20d1f1e5578c8d0

RUN cd /opt && \
  cp -R /opt/owasp-modsecurity-crs/ /etc/nginx/modsecurity.d/owasp-crs/ && \
  mv /etc/nginx/modsecurity.d/owasp-crs/crs-setup.conf.example /etc/nginx/modsecurity.d/owasp-crs/crs-setup.conf && \
  cd /etc/nginx/modsecurity.d && \
  printf "\ninclude owasp-crs/crs-setup.conf\ninclude owasp-crs/rules/REQUEST-901-INITIALIZATION.conf\ninclude owasp-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf\ninclude owasp-crs/rules/REQUEST-910-IP-REPUTATION.conf\ninclude owasp-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf\ninclude owasp-crs/rules/REQUEST-912-DOS-PROTECTION.conf\ninclude owasp-crs/rules/REQUEST-913-SCANNER-DETECTION.conf\ninclude owasp-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf\ninclude owasp-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf\ninclude owasp-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf\ninclude owasp-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf\ninclude owasp-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf\ninclude owasp-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf\ninclude owasp-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf\ninclude owasp-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf\ninclude owasp-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf\ninclude owasp-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf\ninclude owasp-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf\ninclude owasp-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf\ninclude owasp-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf\ninclude owasp-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf\ninclude owasp-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf\ninclude owasp-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf\ninclude owasp-crs/rules/RESPONSE-980-CORRELATION.conf" >> include.conf && \
  sed -i -e 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/nginx/modsecurity.d/modsecurity.conf

COPY docker-entrypoint.sh /
COPY nginx.conf /etc/nginx/
RUN chmod u+x /docker-entrypoint.sh
# Logs to stdout/stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  ln -sf /dev/stdout /var/log/modsec_audit.log

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD /usr/local/nginx/nginx -g "daemon off;"
