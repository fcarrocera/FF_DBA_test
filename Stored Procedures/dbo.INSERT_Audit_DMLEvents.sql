SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[INSERT_Audit_DMLEvents]
AS
WITH cte AS (
SELECT ROW_NUMBER() OVER(PARTITION BY [owt].[session_id] ORDER BY [owt].[wait_duration_ms] DESC) AS RN,
    [owt].[session_id],
	[Host_Name],
	[Program_Name],
	[Login_Name],
    [owt].[wait_duration_ms] / (1000.0) 'Wait Time (in Sec)',
	[er].cpu_time,
	er.logical_reads,
    er.reads,
    er.writes,
    er.total_elapsed_time / (1000.0) 'Elapsed Time (in Sec)',
    [owt].[wait_type],
    [owt].[blocking_session_id],
    [owt].[resource_description],
    CASE [owt].[wait_type]
        WHEN N'CXPACKET' THEN
            RIGHT ([owt].[resource_description],
                CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
        ELSE NULL
    END AS [Node ID],
    --[es].[program_name],
    [est].text,
    dbs.name AS [DatabaseName],
    [eqp].[query_plan],
	--[QueryBlocker] = (select text from sys.dm_exec_sql_text(c.most_recent_sql_handle))
	[estB].text AS QueryBlocker
FROM sys.dm_exec_sessions [es]
INNER JOIN sys.dm_exec_requests [er] ON [es].[session_id] = [er].[session_id]
INNER JOIN sys.databases dbs ON er.database_id=dbs.database_id
LEFT JOIN sys.dm_os_waiting_tasks [owt]		ON [owt].[session_id] = [es].[session_id]
LEFT JOIN sys.dm_os_tasks [ot]		ON [owt].[waiting_task_address] = [ot].[task_address]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
LEFT JOIN sys.dm_exec_requests [erB] ON [owt].[blocking_session_id]=[erB].session_id
OUTER APPLY sys.dm_exec_sql_text ([erB].[sql_handle]) [estB]
LEFT JOIN sys.dm_exec_connections c ON (c.session_id = erB.session_id)
WHERE
    [es].[is_user_process] = 1
AND	es.session_Id > 50              -- Ignore system spids.
--AND s.database_id > 4				-- Ignore system dbs
AND es.session_Id NOT IN (@@SPID)     -- do not include the query we are running
AND [owt].[wait_type] <> 'SP_SERVER_DIAGNOSTICS_SLEEP'
--ORDER BY [owt].[session_id]
)

INSERT INTO [DBA].[dbo].[Audit_DMLEvents]
			([session_id]
			,[Host_Name]
			,[Program_Name]
			,[Login_Name]
           ,[Wait Time (in Sec)]
           ,[cpu_time]
           ,[logical_reads]
           ,[reads]
           ,[writes]
           ,[Elapsed Time (in Sec)]
           ,[wait_type]
           ,[blocking_session_id]
           ,[resource_description]
           ,[Node ID]
           ,[text]
           ,[DatabaseName]
           ,[query_plan]
           ,[QueryBlocker])
SELECT [session_id]
			,CAST([Host_Name] AS VARCHAR)
			,CAST([Program_Name] AS VARCHAR)
			,CAST([Login_Name] AS VARCHAR)
           ,[Wait Time (in Sec)]
           ,[cpu_time]
           ,[logical_reads]
           ,[reads]
           ,[writes]
           ,[Elapsed Time (in Sec)]
           ,CAST([wait_type] AS VARCHAR)
           ,[blocking_session_id]
           ,CAST([resource_description] AS VARCHAR)
           ,CAST([Node ID] AS VARCHAR)
           ,CAST([text] AS VARCHAR)
           ,CAST([DatabaseName] AS VARCHAR)
           ,[query_plan]
           ,CAST([QueryBlocker] AS VARCHAR)
FROM cte
WHERE RN=1;

GO
