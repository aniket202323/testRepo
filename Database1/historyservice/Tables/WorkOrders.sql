CREATE TABLE [historyservice].[WorkOrders] (
    [Id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (255) NULL,
    [ProducedMaterialId] BIGINT         NULL,
    [ProductionLineId]   BIGINT         NULL,
    [RouteDefinitionId]  BIGINT         NULL,
    [WorkOrderId]        BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [U_WRKRDRS_WORKORDERID] UNIQUE NONCLUSTERED ([WorkOrderId] ASC)
);

