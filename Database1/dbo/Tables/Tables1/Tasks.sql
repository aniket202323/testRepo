CREATE TABLE [dbo].[Tasks] (
    [ET_Id]    INT           NULL,
    [IsActive] TINYINT       NULL,
    [Owner]    VARCHAR (30)  NOT NULL,
    [TableId]  INT           NULL,
    [TaskDesc] VARCHAR (100) NOT NULL,
    [TaskId]   INT           NOT NULL,
    CONSTRAINT [Tasks_PK_TaskId] PRIMARY KEY NONCLUSTERED ([TaskId] ASC),
    CONSTRAINT [Tasks_FK_TableId] FOREIGN KEY ([TableId]) REFERENCES [dbo].[Tables] ([TableId])
);


GO
CREATE CLUSTERED INDEX [Tasks_IX_IdOwner]
    ON [dbo].[Tasks]([Owner] ASC, [TaskId] ASC);

