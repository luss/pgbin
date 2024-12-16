
DROP VIEW  IF EXISTS v_versions;
DROP TABLE IF EXISTS versions;
DROP TABLE IF EXISTS releases;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
  category    INTEGER  NOT NULL PRIMARY KEY,
  sort_order  SMALLINT NOT NULL,
  description TEXT     NOT NULL,
  short_desc  TEXT     NOT NULL
);


CREATE TABLE projects (
  project   	 TEXT     NOT NULL PRIMARY KEY,
  category  	 INTEGER  NOT NULL,
  port      	 INTEGER  NOT NULL,
  depends   	 TEXT     NOT NULL,
  start_order    INTEGER  NOT NULL,
  sources_url    TEXT     NOT NULL,
  short_name     TEXT     NOT NULL,
  is_extension   SMALLINT NOT NULL,
  image_file     TEXT     NOT NULL,
  description    TEXT     NOT NULL,
  project_url    TEXT     NOT NULL,
  FOREIGN KEY (category) REFERENCES categories(category)
);


CREATE TABLE releases (
  component     TEXT     NOT NULL PRIMARY KEY,
  sort_order    SMALLINT NOT NULL,
  project       TEXT     NOT NULL,
  disp_name     TEXT     NOT NULL,
  doc_url       TEXT     NOT NULL,
  stage         TEXT     NOT NULL,
  description   TEXT     NOT NULL,
  is_open       SMALLINT NOT NULL DEFAULT 1,
  license       TEXT     NOT NULL,
  is_available  TEXT     NOT NULL,
  available_ver TEXT     NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(project)
);


CREATE TABLE versions (
  component     TEXT    NOT NULL,
  version       TEXT    NOT NULL,
  platform      TEXT    NOT NULL,
  is_current    INTEGER NOT NULL,
  release_date  DATE    NOT NULL,
  parent        TEXT    NOT NULL,
  pre_reqs      TEXT    NOT NULL,
  release_notes TEXT    NOT NULL,
  PRIMARY KEY (component, version),
  FOREIGN KEY (component) REFERENCES releases(component)
);

CREATE VIEW v_versions AS
  SELECT c.category as cat, c.sort_order as cat_sort, r.sort_order as rel_sort,
         c.description as cat_desc, c.short_desc as cat_short_desc,
         p.image_file, r.component, r.project, r.stage, r.disp_name as release_name,
         v.version, p.sources_url, p.project_url, v.platform, 
         v.is_current, v.release_date, p.description as proj_desc, 
         r.description as rel_desc, v.pre_reqs, r.license, p.depends, 
         r.is_available, v.release_notes
    FROM categories c, projects p, releases r, versions v
   WHERE c.category = p.category
     AND p.project = r.project
     AND r.component = v.component;

INSERT INTO categories VALUES (0,   0, 'Hidden', 'NotShown');
INSERT INTO categories VALUES (1,  10, 'Rock-solid Postgres', 'Postgres');
INSERT INTO categories VALUES (11, 30, 'Clustering', 'Cloud');
INSERT INTO categories VALUES (10, 15, 'Streaming Change Data Capture', 'CDC');
INSERT INTO categories VALUES (2,  12, 'Legacy RDBMS', 'Legacy');
INSERT INTO categories VALUES (6,  20, 'Oracle Migration & Compatibility', 'OracleMig');
INSERT INTO categories VALUES (4,  11, 'Postgres Apps & Extensions', 'Extras');
INSERT INTO categories VALUES (5,  25, 'Data Integration', 'Integration');
INSERT INTO categories VALUES (3,  80, 'Database Developers', 'Developers');
INSERT INTO categories VALUES (9,  87, 'Management & Monitoring', 'Manage/Monitor');

-- ## HUB ################################
INSERT INTO projects VALUES ('hub',0, 0, 'hub', 0, 'https://github.com/luss/pgbin','',0,'','','');
INSERT INTO releases VALUES ('hub', 1, 'hub', '', '', 'hidden', '', 1, '', '', '');
INSERT INTO versions VALUES ('hub', '17.2', '',  1, '20241215', '', '', '');

-- ##
INSERT INTO projects VALUES ('pg', 1, 5432, 'hub', 1, 'https://github.com/postgres/postgres/tags',
 'postgres', 0, 'postgresql.png', 'Best RDBMS', 'https://postgresql.org');

INSERT INTO releases VALUES ('pg15', 5, 'pg', '', '', 'test', 
  '<font size=-1 color=red><b>New in <a href=https://sql-info.de/postgresql/postgresql-15/articles-about-new-features-in-postgresql-15.html>2022!</a></b></font>',
  1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('pg15', '15beta1-2',  'el8', 1, '20220519','', 'LIBC-2.28', '');
INSERT INTO versions VALUES ('pg15', '15beta1-1',  'amd, el8, osx', 1, '20220519','', '', '');

INSERT INTO projects VALUES ('ivory14', 6, 5432, 'hub', 1, 'https://github.com/ivorysql/ivorysql/tags',
  'IvorySQL', 0, 'highgo.png', 'Postgres w/ mode=oracle', 'https://ivorysql.org');
INSERT INTO releases VALUES ('ivory14', 10, 'ivory14', 'IvorySQL', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('ivory14', '14.3-1',  'amd', 1, '20220523', '', 'LIBC-2.17', '');

INSERT INTO projects VALUES ('debezium', 10, 8083, '', 3, 'https://debezium.io/releases/1.9/',
  'Debezium', 0, 'debezium.png', 'Heterogeneous CDC', 'https://debezium.io');
INSERT INTO releases VALUES ('debezium', 1, 'debezium', 'Debezium', '', 'test', '', 1, 'Apache', '', '');
INSERT INTO versions VALUES ('debezium', '1.9.2.Final',   '', 1, '20220520', '', '', '');

INSERT INTO projects VALUES ('olr', 10, 8083, '', 3, 'https://github.com/bersler/OpenLogReplicator/releases',
  'OLR', 0, 'olr.png', 'Oracle Binary Log Replicator', 'https://www.bersler.com/openlogreplicator');
INSERT INTO releases VALUES ('olr', 3, 'olr', 'OLR', '', 'test', '', 1, 'GPL', '', '');
INSERT INTO versions VALUES ('olr', '0.9.41-beta',   '', 1, '20220328', '', '', '');
INSERT INTO versions VALUES ('olr', '0.9.40-beta',   '', 0, '20220204', '', '', '');

INSERT INTO projects VALUES ('kafka', 10, 9092, '', 2, 'https://kafka.apache.org/downloads',
  'Kafka', 0, 'kafka.png', 'Streaming Platform', 'https://kafka.apache.org');
INSERT INTO releases VALUES ('kafka', 0, 'kafka', 'Apache Kafka', '', 'test', '', 1, 'Apache', '', '');
INSERT INTO versions VALUES ('kafka', '3.2.0', '', 1, '20220517', '', '', 'https://downloads.apache.org/kafka/3.2.0/RELEASE_NOTES.html');

INSERT INTO projects VALUES ('apicurio', 10, 8080, 'hub', 1, 'https://github.com/apicurio/apicurio-registry/releases',
  'apicurio', 0, 'apicurio.png', 'Schema Registry', 'https://www.apicur.io/registry/');
INSERT INTO releases VALUES ('apicurio', 3, 'apicurio', 'Apicurio', '', 'test', '', 1, 'Apache', '', '');
INSERT INTO versions VALUES ('apicurio', '2.2.3', '',  1, '20220414', '', '', '');

INSERT INTO projects VALUES ('zookeeper', 10, 2181, 'hub', 1, 'https://zookeeper.apache.org/releases.html#releasenotes',
  'zookeeper', 0, 'zookeeper.png', 'Distributed Key-Store for HA', 'https://zookeeper.apache.org');
INSERT INTO releases VALUES ('zookeeper', 3, 'zookeeper', 'Zookeeper', '', 'test', '', 1, 'Apache', '', '');
INSERT INTO versions VALUES ('zookeeper', '3.7.0', '',  0, '20210327', '', '',
  'https://zookeeper.apache.org/doc/r3.7.0/releasenotes.html');

INSERT INTO projects VALUES ('decoderbufs', 10, 0, 'hub', 0, 'https://github.com/debezium/postgres-decoderbufs', 
  'decoderbufs', 1, 'protobuf.png', 'Logical decoding via ProtoBuf', 'https://github.com/debezium/postgres-decoderbufs');
INSERT INTO releases VALUES ('decoderbufs-pg14',  4, 'decoderbufs', 'DecoderBufs', '', 'prod', '', 1, 'MIT', '', '');
INSERT INTO versions VALUES ('decoderbufs-pg14', '1.7.0-1', 'amd', 0, '20211001', 'pg14', '', '');

INSERT INTO projects VALUES ('bqfdw', 5, 0, 'multicorn2', 1, 'https://pypi.org/project/bigquery-fdw/#history',
  'bqfdw', 1, 'bigquery.png', 'BigQuery from PG', 'https://pypi.org/project/bigquery-fdw');
INSERT INTO releases VALUES ('bqfdw-pg14',  3, 'bqfdw', 'BigQueryFDW', '', 'prod', '', 1, 'MIT', '', '');
INSERT INTO versions VALUES ('bqfdw-pg14', '1.9', 'amd',  1, '20211218', 'pg14', '', '');

INSERT INTO projects VALUES ('esfdw', 5, 0, 'multicorn2', 1, 'https://pypi.org/project/pg-es-fdw/#history',
  'esfdw', 1, 'esfdw.png', 'ElasticSearch from PG', 'https://pypi.org/project/pg-es-fdw/');
INSERT INTO releases VALUES ('esfdw-pg14',  4, 'esfdw', 'ElasticSearchFDW', '', 'prod', '', 1, 'MIT', '', '');
INSERT INTO versions VALUES ('esfdw-pg14', '0.11.1', 'amd',  1, '20210409', 'pg14', '', '');

INSERT INTO projects VALUES ('ora2pg', 6, 0, 'hub', 0, 'https://github.com/darold/ora2pg/tags',
  'ora2pg', 0, 'ora2pg.png', 'Migrate from Oracle to PG', 'https://ora2pg.darold.net');
INSERT INTO releases VALUES ('ora2pg', 2, 'ora2pg', 'Oracle to PG', '', 'test', '', 1, 'GPLv2', '', '');
INSERT INTO versions VALUES ('ora2pg', '23.1', '', 1, '20220512', '', '', 'https://github.com/darold/ora2pg/releases/tag/v23.1');

INSERT INTO projects VALUES ('oraclefdw', 6, 0, 'hub', 0, 'https://github.com/laurenz/oracle_fdw/tags',
  'oraclefdw', 1, 'oracle_fdw.png', 'Oracle from PG', 'https://github.com/laurenz/oracle_fdw');
INSERT INTO releases VALUES ('oraclefdw-pg14', 2, 'oraclefdw', 'OracleFDW', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('oraclefdw-pg14','2.4.0-1', 'amd', 1, '20210923', 'pg14', '', 'https://github.com/laurenz/oracle_fdw/releases/tag/ORACLE_FDW_2_4_0');

INSERT INTO projects VALUES ('oracle',  2, 1521, 'hub', 0, 'https://www.oracle.com/database/technologies/oracle-database-software-downloads.html#19c', 
  'oracle', 0, 'oracle.png', 'Oracle Express for Linux', 'https://www.oracle.com/database/technologies');
INSERT INTO releases VALUES ('oracle', 1, 'oracle', 'Oracle', '', 'test','', 0, 'ORACLE', '', '');
INSERT INTO versions VALUES ('oracle', '11', 'amd', 1, '20180501', '', '', '');

INSERT INTO projects VALUES ('instantclient', 6, 0, 'hub', 0, 'https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html', 
  'instantclient', 0, 'instantclient.png', 'Oracle Instant Client', 'https://www.oracle.com/database/technologies/instant-client.html');
INSERT INTO releases VALUES ('instantclient', 2, 'instantclient', 'Instant Client', '', 'test','', 0, 'ORACLE', '', '');
INSERT INTO versions VALUES ('instantclient', '21.6', '', 0, '20220420', '', '', '');

INSERT INTO projects VALUES ('orafce', 6, 0, 'hub', 0, 'https://github.com/orafce/orafce/releases',
  'orafce', 1, 'larry.png', 'Ora Built-in Packages', 'https://github.com/orafce/orafce#orafce---oracles-compatibility-functions-and-packages');
INSERT INTO releases VALUES ('orafce-pg14', 2, 'orafce', 'OraFCE', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('orafce-pg14', '3.21.0-1',  'amd', 1, '20220416', 'pg14', '', '');

INSERT INTO projects VALUES ('fixeddecimal', 6, 0, 'hub', 0, 'https://github.com/pgsql-io/fixeddecimal/tags',
  'fixeddecimal', 1, 'fixeddecimal.png', 'Much faster than NUMERIC', 'https://github.com/pgsql-io/fixeddecimal');
INSERT INTO releases VALUES ('fixeddecimal-pg14', 90, 'fixeddecimal', 'FixedDecimal', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('fixeddecimal-pg14', '1.1.0-1',  'amd', 0, '20201119', 'pg14', '', '');

INSERT INTO projects VALUES ('plv8', 3, 0, 'hub', 0, 'https://github.com/plv8/plv8/tags',
  'plv8',   1, 'v8.png', 'Javascript Stored Procedures', 'https://github.com/plv8/plv8');
INSERT INTO releases VALUES ('plv8-pg12', 4, 'plv8', 'PL/V8', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO releases VALUES ('plv8-pg13', 4, 'plv8', 'PL/V8', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO releases VALUES ('plv8-pg14', 4, 'plv8', 'PL/V8', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('plv8-pg12', '2.3.15-1', 'amd', 0, '20200711', 'pg12', '', '');
INSERT INTO versions VALUES ('plv8-pg13', '2.3.15-1', 'amd', 0, '20200711', 'pg13', '', '');
INSERT INTO versions VALUES ('plv8-pg14', '2.3.15-1', 'amd', 1, '20200711', 'pg14', '', '');

INSERT INTO projects VALUES ('pljava', 3, 0, 'hub', 0, 'https://github.com/tada/pljava/releases', 
  'pljava', 1, 'pljava.png', 'Java Stored Procedures', 'https://github.com/tada/pljava');
INSERT INTO releases VALUES ('pljava-pg13', 7, 'pljava', 'PL/Java', '', 'test', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('pljava-pg13', '1.6.2-1',  'amd',  0, '20201127', 'pg13', '', '');

INSERT INTO projects VALUES ('pldebugger', 3, 0, 'hub', 0, 'https://github.com/EnterpriseDB/pldebugger/tags',
  'pldebugger', 1, 'debugger.png', 'Stored Procedure Debugger', 'https://github.com/EnterpriseDB/pldebugger');
INSERT INTO releases VALUES ('pldebugger-pg12', 2, 'pldebugger', 'PL/Debugger', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO releases VALUES ('pldebugger-pg13', 2, 'pldebugger', 'PL/Debugger', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO releases VALUES ('pldebugger-pg14', 2, 'pldebugger', 'PL/Debugger', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('pldebugger-pg12', '1.4-1',  'amd',  0, '20210923', 'pg12', '', '');
INSERT INTO versions VALUES ('pldebugger-pg13', '1.4-1',  'amd',  0, '20210923', 'pg13', '', '');
INSERT INTO versions VALUES ('pldebugger-pg14', '1.4-1',  'amd',  1, '20210923', 'pg14', '', '');

INSERT INTO projects VALUES ('plprofiler', 3, 0, 'hub', 7, 'https://github.com/bigsql/plprofiler/tags',
  'plprofiler', 1, 'plprofiler.png', 'Stored Procedure Profiler', 'https://github.com/bigsql/plprofiler#plprofiler');
INSERT INTO releases VALUES ('plprofiler-pg14', 0, 'plprofiler',    'PL/Profiler',  '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('plprofiler-pg14', '4.1-1', 'amd', 1, '20211019', 'pg14', '', '');

INSERT INTO projects VALUES ('golang', 4, 0, 'hub', 0, 'https://go.dev/dl',
  'golang', 0, 'go.png', 'Fast & Scaleable Programming', 'https://go.dev');
INSERT INTO releases VALUES ('golang', 9, 'golang', 'GO', '', 'test', '', 1, '', '', '');
INSERT INTO versions VALUES ('golang', '1.17.4', 'amd', 0, '20210812', '', '', '');

INSERT INTO projects VALUES ('walg', 4, 0, 'hub', 0, 'https://github.com/wal-g/wal-g/releases',
  'walg', 0, 'walg.png', 'Archival Restoration Tool', 'https://wal-g.readthedocs.io');
INSERT INTO releases VALUES ('walg', 9, 'walg', 'WAL-G', '', 'test', '', 1, 'Apache', '', '');
INSERT INTO versions VALUES ('walg', '2.0.0', 'amd', 1, '20220519', '', '', '');

INSERT INTO projects VALUES ('backrest', 4, 0, 'hub', 0, 'https://github.com/pgbackrest/pgbackrest/tags',
  'backrest', 0, 'backrest.png', 'Backup & Restore', 'https://pgbackrest.org');
INSERT INTO releases VALUES ('backrest', 9, 'backrest', 'pgBackRest', '', 'included', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('backrest', '2.38', 'amd', 0, '20220307', '', '', 'https://pgbackrest.org/release.html#2.38');

INSERT INTO projects VALUES ('audit', 4, 0, 'hub', 0, 'https://github.com/pgaudit/pgaudit/releases',
  'audit', 1, 'audit.png', 'Audit Logging', 'https://github.com/pgaudit/pgaudit');
INSERT INTO releases VALUES ('audit-pg14', 10, 'audit', 'pgAudit', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('audit-pg14', '1.6.2-1', 'amd', 1, '20220225', 'pg14', '', 'https://github.com/pgaudit/pgaudit/releases/tag/1.6.2');
INSERT INTO versions VALUES ('audit-pg14', '1.6.1-1', 'amd', 0, '20211104', 'pg14', '', 'https://github.com/pgaudit/pgaudit/releases/tag/1.6.1');

INSERT INTO projects VALUES ('hintplan', 6, 0, 'hub', 0, 'https://github.com/ossc-db/pg_hint_plan/tags',
  'hintplan', 1, 'hintplan.png', 'Execution Plan Hints', 'https://github.com/ossc-db/pg_hint_plan');
INSERT INTO releases VALUES ('hintplan-pg14', 10, 'hintplan', 'pgHintPlan', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('hintplan-pg14', '1.4.0-1', 'amd', 1, '20220118', 'pg14', '', 'https://github.com/pghintplan/pghintplan/releases/tag/1.6.0');

INSERT INTO projects VALUES ('anon', 4, 0, 'ddlx', 1, 'https://gitlab.com/dalibo/postgresql_anonymizer/-/tags',
  'anon', 1, 'anon.png', 'Anonymization & Masking', 'https://gitlab.com/dalibo/postgresql_anonymizer/blob/master/README.md');
INSERT INTO releases VALUES ('anon-pg13', 11, 'anon', 'Anonymizer', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO releases VALUES ('anon-pg14', 11, 'anon', 'Anonymizer', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('anon-pg13', '0.9.0-1', 'amd', 0, '20210703', 'pg13', '', '');

INSERT INTO versions VALUES ('anon-pg14', '0.12.0-1', 'amd', 1, '20220413', 'pg14', '', '');
INSERT INTO versions VALUES ('anon-pg14', '0.10.0-1', 'amd', 0, '20220315', 'pg14', '', '');
INSERT INTO versions VALUES ('anon-pg14', '0.9.0-1', 'amd', 0, '20210703', 'pg14', '', '');

INSERT INTO projects VALUES ('citus', 4, 0, 'hub',0, 'https://github.com/citusdata/citus/releases',
  'citus', 1, 'citus.png', 'Distributed PostgreSQL', 'https://github.com/citusdata/citus');
INSERT INTO releases VALUES ('citus-pg14',  0, 'citus', 'Citus', '', 'prod', '', 1, 'AGPLv3', '', '');
INSERT INTO versions VALUES ('citus-pg14', '11.0.2-1', 'amd', 1, '20220616', 'pg14', '', 'https://github.com/citusdata/citus/releases/tag/v11.0.2');

INSERT INTO projects VALUES ('cron', 4, 0, 'hub',0, 'https://github.com/citusdata/pg_cron/releases',
  'cron', 1, 'cron.png', 'Background Job Scheduler', 'https://github.com/citusdata/pg_cron');
INSERT INTO releases VALUES ('cron-pg14', 10, 'cron', 'pgCron', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('cron-pg14', '1.4.1-1', 'amd', 1, '20210925', 'pg14', '', '');

INSERT INTO projects VALUES ('timescaledb', 4, 0, 'hub', 1, 'https://github.com/timescale/timescaledb/releases',
   'timescaledb', 1, 'timescaledb.png', 'Time Series Data', 'https://github.com/timescale/timescaledb/#timescaledb');
INSERT INTO releases VALUES ('timescaledb-pg14',  2, 'timescaledb', 'TimescaleDB', '', 'prod', '', 1, 'Apache', '', '');
INSERT INTO versions VALUES ('timescaledb-pg14', '2.7.0-1',  'amd', 1, '20220524', 'pg14', '', 'https://github.com/timescale/timescaledb/releases/tag/2.7.0');

INSERT INTO projects VALUES ('pglogical', 10, 0, 'hub', 1, 'https://github.com/2ndQuadrant/pglogical/releases',
  'pglogical', 1, 'spock.png', 'Logical Replication', 'https://github.com/2ndQuadrant/pglogical');
INSERT INTO releases VALUES ('pglogical-pg14', 4, 'pglogical', 'pgLogical', '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('pglogical-pg14', '2.4.1-1',  'amd', 1, '20211213', 'pg14', '', 'https://github.com/2ndQuadrant/pglogical/releases/tag/REL2_4_1');

INSERT INTO projects VALUES ('postgis', 4, 1, 'hub', 3, 'http://postgis.net/source',
  'postgis', 1, 'postgis.png', 'Spatial Extensions', 'http://postgis.net');
INSERT INTO releases VALUES ('postgis-pg14', 3, 'postgis', 'PostGIS', '', 'prod', '', 1, 'GPLv2', '', '');
INSERT INTO versions VALUES ('postgis-pg14', '3.2.1-1', 'amd', 1, '20220212', 'pg14', '', 'https://git.osgeo.org/gitea/postgis/postgis/raw/tag/3.2.1/NEWS');

INSERT INTO projects VALUES ('pgadmin', 3, 80, '', 1, 'https://www.pgadmin.org/news/',
  'pgadmin', 0, 'pgadmin.png', 'PostgreSQL Tools', 'https://pgadmin.org');
INSERT INTO releases VALUES ('pgadmin', 2, 'pgadmin', 'pgAdmin 4', '', 'test', '', 1, '', '', '');
INSERT INTO versions VALUES ('pgadmin', '6.9', '', 1, '20220512', '', '', '');

INSERT INTO projects VALUES ('bulkload', 4, 0, 'hub', 5, 'https://github.com/ossc-db/pg_bulkload/releases',
  'bulkload', 1, 'bulkload.png', 'High Speed Data Loading', 'https://github.com/ossc-db/pg_bulkload');
INSERT INTO releases VALUES ('bulkload-pg14', 6, 'bulkload', 'pgBulkLoad',  '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('bulkload-pg14', '3.1.19-1', 'amd', 1, '20211012', 'pg14', '', '');

INSERT INTO projects VALUES ('repack', 4, 0, 'hub', 5, 'https://github.com/reorg/pg_repack/tags',
  'repack', 1, 'repack.png', 'Remove Table/Index Bloat' , 'https://github.com/reorg/pg_repack');
INSERT INTO releases VALUES ('repack-pg14', 6, 'repack', 'pgRepack',  '', 'prod','',  1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('repack-pg14', '1.4.7-1', 'amd', 1, '20211003', 'pg14', '', '');

INSERT INTO projects VALUES ('partman', 4, 0, 'hub', 4, 'https://github.com/pgpartman/pg_partman/tags',
  'partman', 1, 'partman.png', 'Partition Managemnt', 'https://github.com/pgpartman/pg_partman#pg-partition-manager');
INSERT INTO releases VALUES ('partman-pg14', 6, 'partman', 'pgPartman',   '', 'prod', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('partman-pg14', '4.6.1-1',  'amd', 1, '20220415', 'pg14', '', '');

INSERT INTO projects VALUES ('hypopg', 4, 0, 'hub', 8, 'https://github.com/HypoPG/hypopg/releases',
  'hypopg', 1, 'whatif.png', 'Hypothetical Indexes', 'https://hypopg.readthedocs.io/en/latest/');
INSERT INTO releases VALUES ('hypopg-pg14', 99, 'hypopg', 'HypoPG', '', 'prod','',  1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('hypopg-pg14', '1.3.1-1',  'amd', 1, '20210622', 'pg14', '', '');

INSERT INTO projects VALUES ('badger', 4, 0, 'hub', 6, 'https://github.com/darold/pgbadger/releases',
  'badger', 0, 'badger.png', 'Performance Reporting', 'https://pgbadger.darold.net');
INSERT INTO releases VALUES ('badger', 101, 'badger','pgBadger','', 'test', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('badger', '11.8', '', 1, '20220408', '', '', '');

INSERT INTO projects VALUES ('bouncer', 4, 0, 'hub', 3, 'http://pgbouncer.org',
  'bouncer',  0, 'pg-bouncer.png', 'Connection Pooler', 'http://pgbouncer.org');
INSERT INTO releases VALUES ('bouncer', 2, 'bouncer',  'pgBouncer', '', 'included', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('bouncer', '1.17.0', 'amd', 1, '20220323', '', '', '');

INSERT INTO projects VALUES ('patroni', 11, 0, 'haproxy', 4, 'https://github.com/zalando/patroni/releases',
  'patroni', 0, 'patroni.png', 'HA Template', 'https://github.com/zalando/patroni');
INSERT INTO releases VALUES ('patroni', 1, 'patroni', 'Patroni', '', 'test', '', 1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('patroni', '2.1.1', '', 0, '20210819', '', 'UBU20 PYTHON3', 'https://github.com/zalando/patroni/releases/tag/v2.1.1');

INSERT INTO projects VALUES ('multicorn2', 5, 0, 'hub', 0, 'https://github.com/pgsql-io/multicorn2/tags',
  'multicorn2', 1, 'multicorn.png', 'Python FDW Library', 'http://multicorn2.org');
INSERT INTO releases VALUES ('multicorn2-pg14', 01, 'multicorn2', 'Multicorn2', '', 'prod','',  1, 'POSTGRES', '', '');
INSERT INTO versions VALUES ('multicorn2-pg14', '2.3-1', 'amd', 1, '20220509', 'pg14', '', '');
