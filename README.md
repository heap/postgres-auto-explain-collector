# postgres-auto-explain-collector
Code for gathering query plans from auto_explain from the Postgres logs

To use, you need the following Postgres settings on the database you want to
collect the query plans from.

```
shared_preload_libraries = 'auto_explain' # And any other libaries you load.
log_destination = 'csvlog' # And any other log destinations you want.
logging_collector = on
```

You will want to configure auto_explain to include the information you want:
https://www.postgresql.org/docs/current/static/auto-explain.html

Then on the database where you want to send the plans to, you need to define the
following table:

```
CREATE TABLE auto_explain_logs (record JSONB);
```

From there all you need is start the collector on the machine you want to gather plans from with PGUSER and related variables set to the DB you want to send the data to. As an example:

```
PGHOST=target.server.com PGUSER=<target-user> PGPASSWORD=<target-password> PGDATABASE=<target-database> forever start -c coffee node_modules/postgres-auto-explain-collector/bin/postgres-auto-explain-collector.coffee --log-directory <postgres-log-directory>
```
