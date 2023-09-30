CREATE TABLE [dbo].[SpecProp_MaterialSpec_ProdSeg] (
    [Name]                   NVARCHAR (255)   NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [DataType]               INT              NULL,
    [UnitOfMeasure]          NVARCHAR (255)   NULL,
    [TimeStamp]              DATETIME         NULL,
    [Value]                  SQL_VARIANT      NULL,
    [Version]                BIGINT           NULL,
    [MaterialSpec_ProdSegId] UNIQUEIDENTIFIER NOT NULL,
    [ProdSegId]              UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                 UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialSpec_ProdSegId] ASC, [ProdSegId] ASC, [Name] ASC),
    CONSTRAINT [SpecProp_MaterialSpec_ProdSeg_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [SpecProp_MaterialSpec_ProdSeg_MaterialSpec_ProdSeg_Relation1] FOREIGN KEY ([MaterialSpec_ProdSegId], [ProdSegId]) REFERENCES [dbo].[MaterialSpec_ProdSeg] ([MaterialSpec_ProdSegId], [ProdSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecProp_MaterialSpec_ProdSeg_ItemId]
    ON [dbo].[SpecProp_MaterialSpec_ProdSeg]([ItemId] ASC);

