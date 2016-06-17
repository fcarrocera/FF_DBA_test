CREATE TABLE [dbo].[Audit_DMLEvents]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[QueryDatetime] [datetime] NOT NULL CONSTRAINT [DF__Audit_DML__Query__5535A963] DEFAULT (getdate()),
[session_id] [smallint] NULL,
[Host_Name] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Program_Name] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Login_Name] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Wait Time (in Sec)] [numeric] (26, 6) NULL,
[cpu_time] [int] NOT NULL,
[logical_reads] [bigint] NOT NULL,
[reads] [bigint] NOT NULL,
[writes] [bigint] NOT NULL,
[Elapsed Time (in Sec)] [numeric] (17, 6) NULL,
[wait_type] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blocking_session_id] [smallint] NULL,
[resource_description] [varchar] (3100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Node ID] [varchar] (3100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[text] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[query_plan] [xml] NULL,
[QueryBlocker] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[Audit_DMLEvents] ADD CONSTRAINT [PK__Audit_DM__3214EC27371611E5] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
