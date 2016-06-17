SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[test] (
@date DATETIME = NULL
)
AS
SELECT 1
-- this is the new version of the procesdure
GO
