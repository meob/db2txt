# db2txt
Useful SQL scripts for DBA and DEV.

These pure SQL, simple, textual, database configuration and statistics scripts
can be used from any client to extract most intresting information for DBAs and DEVs.
Currently MySQL, PostgreSQL, Oracle, ClickHouse scripts are available.

## Sections

Even if the report contents greatly depend on the database architecture
there are common sections for all databases:

* `summary_info` summary database informations as version, size, number of users, number of objects, ...
* `version` current database version and information about lastest supported versions
* `schema_matrix` reports the number of objects (eg. tables, indexes) for each schema or database
* `user_list` reports the configured users and their grants
* `current_query` reports most intresting information about current database avtivities
* `locks` reports current locks giving precedence to blocking locks
* `tuning_parameters` most intresting tuning parameters and statistics
* `query_top20` most time consuming queries
* `replication` replication and similar features are reported in this section
* `biggest_objects` space usage from different points of view
* `all_parameters` all database parameters
* `global_status` database status details


## Usage

Any SQL client program can be used to execute the 2TXT-Report scripts.

With DBeaver choose the database you want to use (superadmin rights are suggested),
from the "SQL Editor" create a "New SQL Script", paste the 2TXT-Report script,
toggle "Show results in single tab", activate the "SQL Terminal" output tab,
and finally "Execute SQL script" !

Scripts can also be used with native clients too as described in the following sections.


### MySQL

The script can be executed from the native client too:

	mysql -p$PWD  --force -t  <my2txt.sql  2>/dev/null  >my2txt.txt 

All the provided sections are present for MySQL.

Supported version is 8.4 but my2txt is known to work with other versions and forks too.
`SHOW BINARY LOG STATUS` has been introduced in MySQL 8.4 and gives an unimportant
error with previous MySQL versions.


### PostgreSQL

The script can be executed from the native client too:

	psql [database]  <pg2txt.sql  2>/dev/null   >pg2txt.txt 

If already connected with psql the following options give a better formatting:

	\pset footer off
	\o pg.txt
	\i pg2txt.sql 

There are several addictional sections for PostgreSQL: `table_deads` and `table_bloats` for detecting
dead tuples, bloat and vacuum execution; `index_issue` to detect missing indexes, ...
There is not a `global_status` section since PostgreSQL uses several different system views
we collected in the `tuning_parameters` section.

Supported version is 16 but pg2txt is known to work quite well with all supported versions.
Column `toplevel` in `pg_stat_statements` in available in PG 14+, comment it out if using a previous PG version.


### Oracle

The script can be executed from the native client too:

	sqlplus / as sysdba  <ora2txt.sql  2>/dev/null  >ora2txt.txt 

Supported version is 19c but ora2txt is known to work with other versions too even if 12c+ is suggested.


### ClickHouse

The script can be executed from the native client too:

	clickhouse-client -mn --ignore-error -f PrettyCompactMonoBlock --ask-password <ch2txt.sql  2>/dev/null  >ch2txt.txt 

`all_parameters` and `global_status` sections queries are limited to 20 since the number
of available options and statistic is very high in ClickHouse; of course the limit can
be removed if need.

Supported version is 24.8.*-lts but ch2txt is known to work well with other versions too.


## Limits

These are easy SQL scripts: they report only the most intresting information,
only recent, supported and widely used versions are supported
(even if they may work also with older an newer versions), ...

If you want more information and better formatted results use db2html HTML scripts available on
[https://github.com/meob/db2html](https://github.com/meob/db2html).


# LICENSE

Copyright 2024 meob

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
