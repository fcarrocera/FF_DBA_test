SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[DELETE_Audit_DMLEvents] (
@date DATETIME = NULL
)
AS
IF (@date IS NULL)
	SET @date = DATEDIFF(dd,-30, GETDATE());

DELETE 
FROM [dbo].[Audit_DMLEvents]
WHERE [QueryDatetime] < @date;
GO
