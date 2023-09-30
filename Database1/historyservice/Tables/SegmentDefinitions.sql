CREATE TABLE [historyservice].[SegmentDefinitions] (
    [RowId]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [SegmentsDefinition] NVARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([RowId] ASC)
);

