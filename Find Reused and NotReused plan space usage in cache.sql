;with cte as ( 
    select 
        reused = case when usecounts > 1 then 'reused_plan_mb' else 'not_reused_plan_mb' end, 
        size_in_bytes, 
        cacheobjtype, 
        objtype 
    from 
        sys.dm_exec_cached_plans 
), cte2 as 
( 
    select 
        reused, 
        objtype, 
        cacheobjtype, 
        size_in_mb = sum(size_in_bytes / 1024. / 1024.) 
    from 
        cte 
    group by 
        reused, cacheobjtype, objtype 
), cte3 as 
( 
    select 
        * 
    from 
        cte2 c 
    pivot 
        ( sum(size_in_mb) for reused in ([reused_plan_mb], [not_reused_plan_mb])) p 
) 
select 
    objtype, cacheobjtype, [reused_plan_mb] = sum([reused_plan_mb]), [not_reused_plan_mb] = sum([not_reused_plan_mb]) 
from 
    cte3 
group by 
    objtype, cacheobjtype 
with rollup 
having 
    (objtype is null and cacheobjtype is null) or (objtype is not null and cacheobjtype is not null)