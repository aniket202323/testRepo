CREATE TABLE [dbo].[PrdExec_Output_Event_History] (
    [Comment_Id]        INT      NULL,
    [DBTT_Id]           TINYINT  NULL,
    [Entry_On]          DATETIME NOT NULL,
    [Event_Id]          INT      NULL,
    [Event_Id_Updated]  BIT      NULL,
    [History_EntryOn]   DATETIME NULL,
    [Output_Event_Id]   INT      NOT NULL,
    [Timestamp]         DATETIME NOT NULL,
    [Timestamp_Updated] BIT      NULL,
    [Unloaded]          TINYINT  CONSTRAINT [PrdExecOutputEventsHist_DF_Unloaded] DEFAULT ((0)) NOT NULL,
    [Unloaded_Updated]  BIT      NULL,
    [User_Id]           INT      NOT NULL,
    CONSTRAINT [PrdExecOutputHist_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);

