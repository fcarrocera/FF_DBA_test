SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[INSERT_Audit_DMLEvents]
AS
BEGIN TRY
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
		,CAST([Host_Name] AS VARCHAR) AS [Host_Name]
		,CAST([Program_Name] AS VARCHAR) AS [Program_Name]
		,CAST([Login_Name] AS VARCHAR) AS [Login_Name]
		,[Wait Time (in Sec)]
		,[cpu_time]
		,[logical_reads]
		,[reads]
		,[writes]
		,[Elapsed Time (in Sec)]
		,CAST([wait_type] AS VARCHAR) AS [wait_type]
		,[blocking_session_id]
		,CAST([resource_description] AS VARCHAR) AS [resource_description]
		,CAST([Node ID] AS VARCHAR) AS [Node ID]
		,[text] 
		,CAST([DatabaseName] AS VARCHAR) AS [DatabaseName]
		,[query_plan]
		,CAST([QueryBlocker] AS VARCHAR) AS [QueryBlocker]
	FROM cte
	WHERE RN=1;
END TRY 

BEGIN CATCH     

	-- Will not change for duration of SP - this is used to derive overall SP timing & used at normal execution end, 
	-- exception handling & before every RETURN
	DECLARE @SPStart datetime2 = SYSUTCDATETIME()		
			-- Is updated every time a log record is inserted & used to provide duration at SQLstatement level
			,@SPStmtStart datetime2 = SYSUTCDATETIME()
			,@SQLInstanceName sysname = @@servername
			-- Next two LV's are examples of changing passed variables only - normally comment out out or change as required.
			--,@StartDate varchar(10) = coalesce(@RequestedStartDate,'')
			--,@EndDate varchar(10) = coalesce(@RequestedEndDate,'')

	--LV's used in logging
	DECLARE	@RunType varchar(128) = ''
			,@ProcessingStage varchar(1000) = null
			,@SQLToExecute nvarchar(4000) = ''			
			,@ErrorNumber int = 0
			,@ErrorSeverity int 
			,@ErrorProcedure sysname
			,@ErrorMessage varchar(4000) = ''
			,@IsAzureVM bit = 0
			,@counter int = 0
			,@statusmsg VARCHAR(4000) = '' 
			,@RunId int = 0
	/*End of logging local variables*/

   -------------------------------------------------------------------------------------------------------------------------------------------
    --Exception logging to [tblGenericLog]
    --Store error number & message
    select	@ErrorNumber =  error_number(), @ErrorSeverity = error_severity(),  
		  @ErrorProcedure = error_procedure(), @ErrorMessage = ERROR_MESSAGE();

    --Specific format for error message
    select @ErrorMessage =  ' - Error at processing stage: ' + coalesce(@ProcessingStage, ' null @ProcessingStage') + ' - Level ' +
		  case 
			 when @ErrorSeverity <= 10 then convert(varchar(2), @ErrorSeverity) + ' INFO ' 
			 when @ErrorSeverity <= 16 then convert(varchar(2), @ErrorSeverity) + ' ERROR ' 
			 when @ErrorSeverity <= 17 then convert(varchar(2), @ErrorSeverity) + ' ERROR - Insufficient Resources' 
			 when @ErrorSeverity <= 18 then convert(varchar(2), @ErrorSeverity) + ' ERROR - Nonfatal Internal Error Detected' 
			 when @ErrorSeverity <= 19 then convert(varchar(2), @ErrorSeverity) + ' ERROR - SQL Server Error in Resource' 
			 when @ErrorSeverity <= 20 then convert(varchar(2), @ErrorSeverity) + ' ERROR - SQL Server Fatal Error in Current Process' 
			 when @ErrorSeverity <= 21 then convert(varchar(2), @ErrorSeverity) + ' ERROR - SQL Server Fatal Error in Database ID (dbid) Processes' 
			 when @ErrorSeverity <= 22 then convert(varchar(2), @ErrorSeverity) + ' ERROR - SQL Server Fatal Error Table Integrity Suspect' 
			 when @ErrorSeverity <= 22 then convert(varchar(2), @ErrorSeverity) + ' ERROR - SQL Server Fatal Error: Database Integrity Suspect' 
			 when @ErrorSeverity <= 22 then convert(varchar(2), @ErrorSeverity) + ' ERROR - Hardware Error' 
		  end	+
		  ', Error message number: ' + convert(nvarchar(10), @ErrorNumber) + ', ' + @ErrorMessage 


    --Construct exception message for log
    set	@StatusMsg = @SQLInstanceName + @ErrorMessage

    insert dbo.[tblGenericLog] ([RunId], [Category], [Status], [OnInstance], [ForInstance], [Source], [Duration], [Msg], [Parameters]) 
		  select	[RunId] = coalesce(@RunId, 0), [Category] = 'Logging',  [Status] = 'Error',  -- or '?', as appropriate
				    [OnInstance] = @SQLInstanceName, [ForInstance] = '',
				    [Source] = REPLICATE('-', (@@NestLevel * 2)) + '> ' + OBJECT_NAME(@@PROCID) + ' - SP Exception', 
				    [Duration] = convert(bigint, datediff(ms, @SPStart, SYSUTCDATETIME())), 
 				    [Msg] =  @StatusMsg,
					[Parameters] = 
						/*Insert generated Declares & Exec below */
					    'exec dbo.INSERT_Audit_DMLEvents' ;
 
    -------------------------------------------------------------------------------------------------------------------------------------------



  --  IF @@TRANCOUNT > 0
   -- ROLLBACK TRANSACTION
          
    --DECLARE @ErrorNumber INT;     
    --DECLARE @ErrorMessage NVARCHAR(4000);
    --DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    --DECLARE @ErrorProcedure NVARCHAR(128);
    DECLARE @ErrorLine INT;
    DECLARE @err INT

    SELECT  @ErrorNumber = ERROR_NUMBER(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
            @ErrorProcedure = ERROR_PROCEDURE(),
            @ErrorLine = ERROR_LINE(),
            @ErrorMessage = ERROR_MESSAGE();   

    EXEC dbo.usp_Insert_Error_Info @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage, 98

    RAISERROR (@ErrorMessage, -- Message text.
        @ErrorSeverity, -- Severity.
        @ErrorState) -- State.
	
END CATCH
GO
