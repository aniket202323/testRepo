CREATE TABLE [dbo].[ResultSetTypes] (
    [KeyColumnNum]  INT          NULL,
    [Message_Id]    INT          NULL,
    [PostColumnNum] INT          NULL,
    [PostRouteId]   INT          NULL,
    [PreColumnNum]  INT          NULL,
    [PreRouteId]    INT          NULL,
    [RSTDesc]       VARCHAR (50) NOT NULL,
    [RSTId]         INT          NOT NULL,
    CONSTRAINT [ResultSetTypes_PK_RSTId] PRIMARY KEY CLUSTERED ([RSTId] ASC),
    CONSTRAINT [ResultSetTypes_FK_MessageTypes] FOREIGN KEY ([Message_Id]) REFERENCES [dbo].[Message_Types] ([Message_Id]) ON DELETE CASCADE
);

