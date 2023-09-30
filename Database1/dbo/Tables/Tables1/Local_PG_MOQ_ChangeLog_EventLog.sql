CREATE TABLE [dbo].[Local_PG_MOQ_ChangeLog_EventLog] (
    [PFEvent_Id] INT            IDENTITY (1, 1) NOT NULL,
    [PFdb_Id]    INT            NOT NULL,
    [PFUser_Id]  INT            NOT NULL,
    [PFApp_Id]   INT            NOT NULL,
    [DocId]      VARCHAR (100)  NOT NULL,
    [Context]    VARCHAR (1000) NOT NULL,
    [Change]     VARCHAR (8000) NOT NULL,
    [LargeParm1] VARCHAR (8000) NULL,
    [LargeParm2] VARCHAR (8000) NULL,
    [CalledBy]   VARCHAR (1000) NULL,
    [Timestamp]  DATETIME       NOT NULL,
    [Entry_On]   DATETIME       NOT NULL,
    CONSTRAINT [LocalPGMOQChangeLogEventLog_PK_PFEventId] PRIMARY KEY CLUSTERED ([PFEvent_Id] ASC),
    CONSTRAINT [LocalPGMOQChangeLogEventLog_FK_PFAppId] FOREIGN KEY ([PFApp_Id]) REFERENCES [dbo].[Local_PG_MOQ_ChangeLog_Application] ([PFApp_Id]),
    CONSTRAINT [LocalPGMOQChangeLogEventLog_FK_PFdbId] FOREIGN KEY ([PFdb_Id]) REFERENCES [dbo].[Local_PG_MOQ_ChangeLog_Database] ([PFdB_Id]),
    CONSTRAINT [LocalPGMOQChangeLogEventLog_FK_PFUserId] FOREIGN KEY ([PFUser_Id]) REFERENCES [dbo].[Local_PG_MOQ_ChangeLog_Users] ([PFUser_Id])
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMOQChangeLogEventLog_IDX_Timestamp]
    ON [dbo].[Local_PG_MOQ_ChangeLog_EventLog]([Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMOQChangeLogEventLog_IDX_EntryOn]
    ON [dbo].[Local_PG_MOQ_ChangeLog_EventLog]([Entry_On] ASC);

