CREATE TABLE [WorkOrder].[HoldRecordMaterialLotActuals] (
    [HoldRecordId]        BIGINT NOT NULL,
    [MaterialLotActualId] BIGINT NOT NULL,
    CONSTRAINT [PK_HoldRecordMaterialLotActuals] PRIMARY KEY CLUSTERED ([HoldRecordId] ASC, [MaterialLotActualId] ASC),
    CONSTRAINT [FK_HoldRecordMaterialLotActuals_HoldRecords_HoldRecordId] FOREIGN KEY ([HoldRecordId]) REFERENCES [WorkOrder].[HoldRecords] ([Id]),
    CONSTRAINT [FK_HoldRecordMaterialLotActuals_MaterialLotActuals_MaterialLotActualId] FOREIGN KEY ([MaterialLotActualId]) REFERENCES [WorkOrder].[MaterialLotActuals] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_HoldRecordMaterialLotActuals_MaterialLotActualId]
    ON [WorkOrder].[HoldRecordMaterialLotActuals]([MaterialLotActualId] ASC);

