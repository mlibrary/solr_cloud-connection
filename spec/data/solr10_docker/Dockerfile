FROM solr:10

ENV SOLR_AUTH_TYPE="basic"
ENV SOLR_AUTHENTICATION_OPTS="-Dsolr.security.auth.basicauth.credentials=solr:SolrRocks"
ENV SOLR_OPTS="-Denable.packages=true"

COPY --chown=solr:solr security.json /var/solr/data/security.json
COPY --chown=solr:solr solr_init.sh /usr/bin/solr_init.sh
ENTRYPOINT ["/usr/bin/solr_init.sh"]
