CREATE TABLE [dbo].[Research_Status] (
    [Research_Status_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Research_Status_Desc] [dbo].[Varchar_Desc] NULL,
    CONSTRAINT [ResStatus_PK_ResStatusId] PRIMARY KEY NONCLUSTERED ([Research_Status_Id] ASC),
    CONSTRAINT [ResStatus_UC_ResStatusDesc] UNIQUE NONCLUSTERED ([Research_Status_Desc] ASC)
);

