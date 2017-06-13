--
-- SQL 2008 TDE Setup and Administration
--
-- List status of XX_DATABASE_XX TDE encryption
-- 
-- Sean Elliott
-- sean_p_elliott@yahoo.co.uk
--
-- February 2011
--

-- Is XX_DATABASE_XX encrypted?
select   db_name(database_id),
         case encryption_state 
            when 0 then '0 - No database encryption key present, no encryption'
            when 1 then '1 - Unencrypted'
            when 2 then '2 - Encryption in progress'
            when 3 then '3 - Encrypted'
            when 4 then '4 - Key change in progress'
            when 5 then '5 - Decryption in progress'
         end encryption_state_desc,
         *
from sys.dm_database_encryption_keys;

-- Have we got the expected server certificate?
select * from master.sys.certificates where name = 'TDEServerCertificate'

-- Does the thumbprint of the certificate match the thumbprint of the database encryption?
select 'Thumbprints match', db_name(dek.database_id), ctf.thumbprint cert_thumbprint, dek.encryptor_thumbprint dek_thumbprint
from sys.dm_database_encryption_keys dek
join  master.sys.certificates ctf
on dek.encryptor_thumbprint = ctf.thumbprint
and db_name(dek.database_id) = 'XX_DATABASE_XX'

union

select 'Thumbprints DO NOT match', db_name(database_id), ctf.thumbprint cert_thumbprint, dek.encryptor_thumbprint dek_thumbprint
from sys.dm_database_encryption_keys dek
join  master.sys.certificates ctf
on dek.encryptor_thumbprint != ctf.thumbprint
and db_name(dek.database_id) = 'XX_DATABASE_XX'
and ctf.name = 'TDEServerCertificate'
