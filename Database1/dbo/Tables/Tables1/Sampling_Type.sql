CREATE TABLE [dbo].[Sampling_Type] (
    [ST_Id]   TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ST_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Sampling_Type_PK_STId] PRIMARY KEY CLUSTERED ([ST_Id] ASC),
    CONSTRAINT [Sampling_Type_UC_STDesc] UNIQUE NONCLUSTERED ([ST_Desc] ASC)
);

