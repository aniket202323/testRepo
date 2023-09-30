CREATE TABLE [WorkOrder].[SegmentActuals] (
    [Id]                           BIGINT             NOT NULL,
    [MaterialLotActualId]          BIGINT             NOT NULL,
    [SegmentId]                    BIGINT             NOT NULL,
    [PU_Id]                        BIGINT             NULL,
    [Status]                       INT                NOT NULL,
    [NumberOfActiveOperationHolds] BIGINT             NOT NULL,
    [CompletedBy]                  NVARCHAR (MAX)     NULL,
    [CompletedOn]                  DATETIMEOFFSET (7) NULL,
    [ReadyOn]                      DATETIMEOFFSET (7) NULL,
    [StartedBy]                    NVARCHAR (MAX)     NULL,
    [StartedOn]                    DATETIMEOFFSET (7) NULL,
    [CompletedQuantity]            INT                NULL,
    CONSTRAINT [PK_SegmentActuals] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_SegmentActuals_MaterialLotActuals_MaterialLotActualId] FOREIGN KEY ([MaterialLotActualId]) REFERENCES [WorkOrder].[MaterialLotActuals] ([Id]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_SegmentActuals_MaterialLotActualId_SegmentId]
    ON [WorkOrder].[SegmentActuals]([MaterialLotActualId] ASC, [SegmentId] ASC);

