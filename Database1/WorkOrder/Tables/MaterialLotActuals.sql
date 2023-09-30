CREATE TABLE [WorkOrder].[MaterialLotActuals] (
    [Id]                               BIGINT         NOT NULL,
    [LotIdentifier]                    NVARCHAR (100) NULL,
    [WorkOrderId]                      BIGINT         NOT NULL,
    [Status]                           INT            NOT NULL,
    [ConcurrencyToken]                 ROWVERSION     NULL,
    [NumberOfIncompleteSegmentActuals] BIGINT         NOT NULL,
    [NumberOfActiveLotHolds]           BIGINT         NOT NULL,
    [PlannedQuantity]                  INT            NOT NULL,
    [InitialPlannedQuantity]           INT            NULL,
    CONSTRAINT [PK_MaterialLotActuals] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_MaterialLotActuals_WorkOrders_WorkOrderId] FOREIGN KEY ([WorkOrderId]) REFERENCES [WorkOrder].[WorkOrders] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialLotActuals_WorkOrderId]
    ON [WorkOrder].[MaterialLotActuals]([WorkOrderId] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_MaterialLotActuals_LotIdentifier_WorkOrderId]
    ON [WorkOrder].[MaterialLotActuals]([LotIdentifier] ASC, [WorkOrderId] ASC) WHERE ([LotIdentifier] IS NOT NULL);

