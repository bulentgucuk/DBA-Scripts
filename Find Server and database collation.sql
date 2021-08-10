/*** Find Server and database collation ***/
SELECT CONVERT (varchar, SERVERPROPERTY('collation')) AS 'server_collation',collationproperty(CONVERT (varchar, SERVERPROPERTY('collation')), 'codepage') AS server_codepage ,
db.name AS datebase_name, db.collation_name AS datebase_collation, collationproperty(db.collation_name, 'codepage') AS datebase_codepage FROM sys.databases AS db
where collationproperty(CONVERT (varchar, SERVERPROPERTY('collation')), 'codepage') != collationproperty(db.collation_name, 'codepage')
