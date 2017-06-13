/* Healthy SQL - Chapter 10 - Surviving the Audit - Policy Based Management (PBM) - 
    please run these separately as needed and refer to the book for proper context and run instructions */

/*Run to see currently enabled policies*/

SELECT name
, description, date_created
FROM msdb.dbo.syspolicy_policies
order by date_created desc

