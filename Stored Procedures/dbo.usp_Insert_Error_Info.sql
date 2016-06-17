SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ======================================================================================================================================== 
--
--
-- ======================================================================================================================================== 

CREATE PROCEDURE [dbo].[usp_Insert_Error_Info] 
	
	@ErrorNumber int, 
	@ErrorSeverity int,
	@ErrorState int,
    @ErrorProcedure nvarchar(128),
    @ErrorLine int,
    @ErrorMessage nvarchar(4000),
    @SprocId int
AS
BEGIN

    -- Insert statements for procedure here
	INSERT INTO dbo.ErrorLog( [ErrorNumber]
      ,[ErrorSeverity]
      ,[ErrorState]
      ,[ErrorProcedure]
      ,[SprocId]
      ,[ErrorLine]
      ,[ErrorMessage]
      ,[EntryDate])
      VALUES(@ErrorNumber, 
	@ErrorSeverity,
	@ErrorState,
    @ErrorProcedure,
    @SprocId,
    @ErrorLine,
    @ErrorMessage, GETDATE())
    
END
GO
