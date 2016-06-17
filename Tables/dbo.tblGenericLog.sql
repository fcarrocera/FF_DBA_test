CREATE TABLE [dbo].[tblGenericLog]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[DateTimeStampUTC] [datetime2] NOT NULL CONSTRAINT [DF_GenericLog_DateTimeStamp] DEFAULT (sysutcdatetime()),
[Category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Source] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Duration] [bigint] NULL CONSTRAINT [DF_tblGenericLog_Duration] DEFAULT ((0)),
[Msg] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[User] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_tblGenericLog_User] DEFAULT (suser_name()),
[Status] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_tblGenericLog_Status] DEFAULT ('Info'),
[OnInstance] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_tblGenericLog_OnInstance] DEFAULT (@@servername),
[ForInstance] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_tblGenericLog_ForInstance] DEFAULT (@@servername),
[SPID] [smallint] NULL CONSTRAINT [DF_tblGenericLog_SPID] DEFAULT (@@spid),
[OperationType] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_tblGenericLog_OperationType] DEFAULT (''),
[RowCount] [bigint] NULL CONSTRAINT [DF_tblGenericLog_RowCount] DEFAULT ((0)),
[Parameters] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RunId] [int] NULL,
[ETLPackage] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ETLSproc] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ETLTask] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ETLEventHandler] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ETLLevel] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_tblGenericLog_Level] DEFAULT ('SQL')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
