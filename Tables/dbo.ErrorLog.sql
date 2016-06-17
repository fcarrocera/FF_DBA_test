CREATE TABLE [dbo].[ErrorLog]
(
[Id] [bigint] NOT NULL IDENTITY(1, 1),
[ErrorNumber] [int] NULL,
[ErrorSeverity] [int] NULL,
[ErrorState] [int] NULL,
[ErrorProcedure] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SprocId] [int] NULL,
[ErrorLine] [int] NULL,
[ErrorMessage] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EntryDate] [smalldatetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ErrorLog] ADD CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED  ([Id]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
