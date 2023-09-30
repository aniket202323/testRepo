CREATE TABLE [dbo].[Local_PE_Logs] (
    [Log_Id]     INT            IDENTITY (1, 1) NOT NULL,
    [LogType_Id] INT            NOT NULL,
    [Path_Id]    INT            NULL,
    [Message]    NVARCHAR (MAX) NULL,
    [User_Id]    INT            NOT NULL,
    [Entry_On]   DATETIME       NOT NULL,
    [Closed_By]  INT            NULL,
    [Closed_On]  DATETIME       NULL,
    CONSTRAINT [PK_Local_PE_Logs] PRIMARY KEY CLUSTERED ([Log_Id] ASC),
    CONSTRAINT [FK_Local_PE_Logs_Local_PE_LogTypes] FOREIGN KEY ([LogType_Id]) REFERENCES [dbo].[Local_PE_LogTypes] ([LogType_Id])
);


GO
CREATE NONCLUSTERED INDEX [Log_By_Type_Path_ClosedBy]
    ON [dbo].[Local_PE_Logs]([LogType_Id] ASC, [Path_Id] ASC, [Closed_By] ASC);


GO
CREATE NONCLUSTERED INDEX [Log_By_Type_Path_EntryOn]
    ON [dbo].[Local_PE_Logs]([LogType_Id] ASC, [Path_Id] ASC, [Entry_On] ASC);


GO
CREATE NONCLUSTERED INDEX [PE_Logs_Entry_On]
    ON [dbo].[Local_PE_Logs]([Entry_On] ASC);

