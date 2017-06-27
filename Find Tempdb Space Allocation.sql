select top 20
    tsu.session_id,
    tsu.request_id,
    r.command,
    s.login_name,
    s.host_name,
    s.program_name,
    total_objects_alloc_page_count = 
        tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count,
    tsu.user_objects_alloc_page_count,
    tsu.user_objects_dealloc_page_count,
    tsu.internal_objects_alloc_page_count,
    tsu.internal_objects_dealloc_page_count,
    st.text
from sys.dm_db_task_space_usage tsu
inner join sys.dm_exec_requests r
on tsu.session_id = r.session_id
and tsu.request_id = r.request_id
inner join sys.dm_exec_sessions s
on r.session_id = s.session_id
outer apply sys.dm_exec_sql_text(r.sql_handle) st
where tsu.user_objects_alloc_page_count > 0
or tsu.internal_objects_alloc_page_count > 0
order by total_objects_alloc_page_count desc;

