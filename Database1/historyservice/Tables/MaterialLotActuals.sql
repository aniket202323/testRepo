CREATE TABLE [historyservice].[MaterialLotActuals] (
    [RowId]                BIGINT         IDENTITY (1, 1) NOT NULL,
    [CurrentLotIdentifier] NVARCHAR (255) NULL,
    [MaterialLotActualsId] BIGINT         NULL,
    [WorkOrderId]          BIGINT         NULL,
    [LotIdentifier]        NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([RowId] ASC),
    CONSTRAINT [U_MTRLTLS_MATERIALLOTACTUALSID] UNIQUE NONCLUSTERED ([MaterialLotActualsId] ASC)
);

