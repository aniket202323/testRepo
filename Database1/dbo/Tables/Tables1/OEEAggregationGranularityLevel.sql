CREATE TABLE [dbo].[OEEAggregationGranularityLevel] (
    [Granularity_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [Granularity_Desc] VARCHAR (100) NOT NULL,
    CONSTRAINT [OEEGranularityLevel_PK_GranularityId] PRIMARY KEY CLUSTERED ([Granularity_Id] ASC),
    CONSTRAINT [OEEGranularityLevel_UC_GranularityDesc] UNIQUE NONCLUSTERED ([Granularity_Desc] ASC)
);

