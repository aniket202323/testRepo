CREATE TABLE [dbo].[WorkDataClass_WorkDataProperty] (
    [r_Order]                    INT              NULL,
    [Value]                      SQL_VARIANT      NULL,
    [Quality]                    SMALLINT         NULL,
    [TimeStamp]                  DATETIME         NULL,
    [Version]                    BIGINT           NULL,
    [WorkDataClassClassId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkDataPropertyPropertyId] UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([WorkDataClassClassId] ASC, [WorkDataPropertyPropertyId] ASC),
    CONSTRAINT [WorkDataClass_WorkDataProperty_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [WorkDataClass_WorkDataProperty_WorkDataClass_Relation1] FOREIGN KEY ([WorkDataClassClassId]) REFERENCES [dbo].[WorkDataClass] ([WorkDataClassClassId]),
    CONSTRAINT [WorkDataClass_WorkDataProperty_WorkDataProperty_Relation1] FOREIGN KEY ([WorkDataPropertyPropertyId]) REFERENCES [dbo].[WorkDataProperty] ([WorkDataPropertyPropertyId])
);


GO
CREATE NONCLUSTERED INDEX [NC_WorkDataClass_WorkDataProperty_WorkDataPropertyPropertyId]
    ON [dbo].[WorkDataClass_WorkDataProperty]([WorkDataPropertyPropertyId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WorkDataClass_WorkDataProperty_ItemId]
    ON [dbo].[WorkDataClass_WorkDataProperty]([ItemId] ASC);

