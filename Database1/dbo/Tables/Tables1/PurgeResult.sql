CREATE TABLE [dbo].[PurgeResult] (
    [PurgeResult_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PurgeResult_Date] DATETIME     CONSTRAINT [PurgeResult_DF_PurgeResultDate] DEFAULT (getdate()) NOT NULL,
    [PurgeResult_Desc] VARCHAR (50) NOT NULL,
    [PurgeResult_Recs] INT          NOT NULL,
    [RunId]            INT          NULL,
    [TotalSeconds]     INT          NULL,
    CONSTRAINT [PurgeResult_PK_PurgeResultId] PRIMARY KEY CLUSTERED ([PurgeResult_Id] ASC)
);

