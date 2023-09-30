CREATE TABLE [WorkOrder].[HoldRecords] (
    [Id]                  BIGINT             NOT NULL,
    [HoldType]            INT                NOT NULL,
    [MaterialLotActualId] BIGINT             NULL,
    [ReasonDescription]   NVARCHAR (150)     NULL,
    [Active]              BIT                NOT NULL,
    [HoldCreatedBy]       NVARCHAR (MAX)     NOT NULL,
    [HoldCreatedTime]     DATETIMEOFFSET (7) NOT NULL,
    [HoldReleasedBy]      NVARCHAR (MAX)     NULL,
    [HoldReleasedTime]    DATETIMEOFFSET (7) NULL,
    [WorkOrderId]         BIGINT             NULL,
    CONSTRAINT [PK_HoldRecords] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_HoldRecords_MaterialLotActuals_MaterialLotActualId] FOREIGN KEY ([MaterialLotActualId]) REFERENCES [WorkOrder].[MaterialLotActuals] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_HoldRecords_WorkOrders_WorkOrderId] FOREIGN KEY ([WorkOrderId]) REFERENCES [WorkOrder].[WorkOrders] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_HoldRecords_MaterialLotActualId]
    ON [WorkOrder].[HoldRecords]([MaterialLotActualId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_HoldRecords_WorkOrderId]
    ON [WorkOrder].[HoldRecords]([WorkOrderId] ASC);

