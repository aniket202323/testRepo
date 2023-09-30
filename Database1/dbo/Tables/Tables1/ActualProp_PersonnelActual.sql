CREATE TABLE [dbo].[ActualProp_PersonnelActual] (
    [Name]              NVARCHAR (255)   NOT NULL,
    [Description]       NVARCHAR (255)   NULL,
    [DataType]          INT              NULL,
    [UnitOfMeasure]     NVARCHAR (255)   NULL,
    [TimeStamp]         DATETIME         NULL,
    [Value]             SQL_VARIANT      NULL,
    [Version]           BIGINT           NULL,
    [PersonnelActualId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PersonnelActualId] ASC, [Name] ASC),
    CONSTRAINT [ActualProp_PersonnelActual_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [ActualProp_PersonnelActual_PersonnelActual_Relation1] FOREIGN KEY ([PersonnelActualId]) REFERENCES [dbo].[PersonnelActual] ([PersonnelActualId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ActualProp_PersonnelActual_ItemId]
    ON [dbo].[ActualProp_PersonnelActual]([ItemId] ASC);

