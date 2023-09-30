CREATE TABLE [WorkOrder].[SegmentDetails] (
    [Id]                   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SegmentsDefinitionId] BIGINT          NOT NULL,
    [SegmentId]            BIGINT          NOT NULL,
    [SegmentName]          NVARCHAR (100)  NULL,
    [SegmentDescription]   NVARCHAR (1000) NULL,
    CONSTRAINT [PK_SegmentDetails] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_SegmentDetails_SegmentsDefinitions_SegmentsDefinitionId] FOREIGN KEY ([SegmentsDefinitionId]) REFERENCES [WorkOrder].[SegmentsDefinitions] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentDetails_SegmentsDefinitionId]
    ON [WorkOrder].[SegmentDetails]([SegmentsDefinitionId] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SegmentDetails_SegmentId_SegmentsDefinitionId]
    ON [WorkOrder].[SegmentDetails]([SegmentId] ASC, [SegmentsDefinitionId] ASC);

