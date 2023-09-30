CREATE TABLE [WorkOrder].[SegmentsDefinitions] (
    [Id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [RouteId]          BIGINT         NULL,
    [SegmentsDocument] NVARCHAR (MAX) NOT NULL,
    [ConcurrencyToken] ROWVERSION     NULL,
    CONSTRAINT [PK_SegmentsDefinitions] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SegmentsDefinitions_RouteId]
    ON [WorkOrder].[SegmentsDefinitions]([RouteId] ASC) WHERE ([RouteId] IS NOT NULL);

