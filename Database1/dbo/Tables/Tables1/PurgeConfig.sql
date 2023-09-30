CREATE TABLE [dbo].[PurgeConfig] (
    [Purge_Id]         INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Purge_Date]       DATETIME      CONSTRAINT [PurgeConfig_DF_Date] DEFAULT (getutcdate()) NOT NULL,
    [Purge_Desc]       VARCHAR (256) NOT NULL,
    [TimeSliceMinutes] INT           NULL,
    CONSTRAINT [PurgeConfig_PK_PurgeId] PRIMARY KEY NONCLUSTERED ([Purge_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PurgeConfig_IX_PurgeDesc]
    ON [dbo].[PurgeConfig]([Purge_Desc] ASC);

