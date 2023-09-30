CREATE TABLE [dbo].[ActualProp_MaterialActual] (
    [Name]             NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (255)   NULL,
    [DataType]         INT              NULL,
    [UnitOfMeasure]    NVARCHAR (255)   NULL,
    [TimeStamp]        DATETIME         NULL,
    [Value]            SQL_VARIANT      NULL,
    [Version]          BIGINT           NULL,
    [MaterialActualId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]           UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialActualId] ASC, [Name] ASC),
    CONSTRAINT [ActualProp_MaterialActual_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [ActualProp_MaterialActual_MaterialActual_Relation1] FOREIGN KEY ([MaterialActualId]) REFERENCES [dbo].[MaterialActual] ([MaterialActualId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ActualProp_MaterialActual_ItemId]
    ON [dbo].[ActualProp_MaterialActual]([ItemId] ASC);

