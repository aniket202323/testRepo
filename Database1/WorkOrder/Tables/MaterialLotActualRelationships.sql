CREATE TABLE [WorkOrder].[MaterialLotActualRelationships] (
    [ParentId] BIGINT NOT NULL,
    [ChildId]  BIGINT NOT NULL,
    CONSTRAINT [PK_MaterialLotActualRelationships] PRIMARY KEY CLUSTERED ([ChildId] ASC, [ParentId] ASC),
    CONSTRAINT [FK_MaterialLotActualRelationships_MaterialLotActuals_ChildId] FOREIGN KEY ([ChildId]) REFERENCES [WorkOrder].[MaterialLotActuals] ([Id]),
    CONSTRAINT [FK_MaterialLotActualRelationships_MaterialLotActuals_ParentId] FOREIGN KEY ([ParentId]) REFERENCES [WorkOrder].[MaterialLotActuals] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_MaterialLotActualRelationships_ParentId]
    ON [WorkOrder].[MaterialLotActualRelationships]([ParentId] ASC);

