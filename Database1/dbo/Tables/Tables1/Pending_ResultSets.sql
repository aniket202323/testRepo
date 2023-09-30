CREATE TABLE [dbo].[Pending_ResultSets] (
    [RS_Id]     BIGINT   IDENTITY (1, 1) NOT NULL,
    [Entry_On]  DATETIME NOT NULL,
    [Processed] BIT      NOT NULL,
    [RS_Value]  XML      NOT NULL,
    [User_Id]   INT      NULL,
    CONSTRAINT [PendingResultSets_PK_RSIdProcessed] PRIMARY KEY CLUSTERED ([RS_Id] ASC, [Processed] ASC),
    CONSTRAINT [PendingResultSets_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);

