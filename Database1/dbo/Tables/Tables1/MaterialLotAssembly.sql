CREATE TABLE [dbo].[MaterialLotAssembly] (
    [Version]             BIGINT           NULL,
    [ParentMaterialLotId] UNIQUEIDENTIFIER NOT NULL,
    [ChildMaterialLotId]  UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ParentMaterialLotId] ASC, [ChildMaterialLotId] ASC),
    CONSTRAINT [MaterialLotAssembly_MaterialLot_Relation1] FOREIGN KEY ([ParentMaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [MaterialLotAssembly_MaterialLot_Relation2] FOREIGN KEY ([ChildMaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId])
);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialLotAssembly_ChildMaterialLotId]
    ON [dbo].[MaterialLotAssembly]([ChildMaterialLotId] ASC);

