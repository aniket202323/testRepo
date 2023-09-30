CREATE TABLE [WorkOrder].[SegmentValidUnits] (
    [Id]                   BIGINT IDENTITY (1, 1) NOT NULL,
    [SegmentsDefinitionId] BIGINT NOT NULL,
    [SegmentId]            BIGINT NOT NULL,
    [ValidOnUnitId]        BIGINT NOT NULL,
    CONSTRAINT [PK_SegmentValidUnits] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_SegmentValidUnits_SegmentsDefinitions_SegmentsDefinitionId] FOREIGN KEY ([SegmentsDefinitionId]) REFERENCES [WorkOrder].[SegmentsDefinitions] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_SegmentValidUnits_SegmentsDefinitionId_SegmentId]
    ON [WorkOrder].[SegmentValidUnits]([SegmentsDefinitionId] ASC, [SegmentId] ASC);

