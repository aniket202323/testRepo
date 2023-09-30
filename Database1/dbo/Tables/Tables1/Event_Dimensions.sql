CREATE TABLE [dbo].[Event_Dimensions] (
    [ED_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ED_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [EventDimensions_PK_EDId] PRIMARY KEY NONCLUSTERED ([ED_Id] ASC)
);

