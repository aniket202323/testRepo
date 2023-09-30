CREATE TABLE [dbo].[MaterialLotProperty] (
    [Name]          NVARCHAR (255)   NOT NULL,
    [Description]   NVARCHAR (255)   NULL,
    [DataType]      INT              NULL,
    [UnitOfMeasure] NVARCHAR (255)   NULL,
    [TimeStamp]     DATETIME         NULL,
    [Value]         SQL_VARIANT      NULL,
    [Version]       BIGINT           NULL,
    [MaterialLotId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]        UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialLotId] ASC, [Name] ASC),
    CONSTRAINT [MaterialLotProperty_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [MaterialLotProperty_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId])
);


GO
CREATE NONCLUSTERED INDEX [NC_MaterialLotProperty_ItemId]
    ON [dbo].[MaterialLotProperty]([ItemId] ASC);

