CREATE TABLE [dbo].[SpecProp_MaterialSpec_ProcSeg] (
    [Name]                   NVARCHAR (255)   NOT NULL,
    [Description]            NVARCHAR (255)   NULL,
    [DataType]               INT              NULL,
    [UnitOfMeasure]          NVARCHAR (255)   NULL,
    [TimeStamp]              DATETIME         NULL,
    [Value]                  SQL_VARIANT      NULL,
    [Version]                BIGINT           NULL,
    [MaterialSpec_ProcSegId] UNIQUEIDENTIFIER NOT NULL,
    [ProcSegId]              UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                 UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialSpec_ProcSegId] ASC, [ProcSegId] ASC, [Name] ASC),
    CONSTRAINT [SpecProp_MaterialSpec_ProcSeg_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [SpecProp_MaterialSpec_ProcSeg_MaterialSpec_ProcSeg_Relation1] FOREIGN KEY ([MaterialSpec_ProcSegId], [ProcSegId]) REFERENCES [dbo].[MaterialSpec_ProcSeg] ([MaterialSpec_ProcSegId], [ProcSegId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SpecProp_MaterialSpec_ProcSeg_ItemId]
    ON [dbo].[SpecProp_MaterialSpec_ProcSeg]([ItemId] ASC);

