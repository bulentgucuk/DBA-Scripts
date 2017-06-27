
-- Find Page Splits for All Index Pages
select AllocUnitName, count([AllocUnitName]) [Splits]
from ::fn_dblog(null, null)
where Operation = N'LOP_DELETE_SPLIT' and parsename(AllocUnitName,3) <> 'sys'
group by AllocUnitName



