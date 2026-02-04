FROM postgres:17-alpine

WORKDIR /bootstrap
COPY bootstrap.sql .

ENTRYPOINT ["sh", "-c"]
CMD ["psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f bootstrap.sql"]