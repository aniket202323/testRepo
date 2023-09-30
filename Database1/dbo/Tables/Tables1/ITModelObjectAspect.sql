CREATE TABLE [dbo].[ITModelObjectAspect] (
    [ITModelObjectAspectPkId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                 BIGINT           NULL,
    [Origin1Type]             NVARCHAR (255)   NULL,
    [Origin1Name]             NVARCHAR (255)   NULL,
    PRIMARY KEY CLUSTERED ([ITModelObjectAspectPkId] ASC),
    CONSTRAINT [ITModelObjectAspect_ITModelObject_Relation1] FOREIGN KEY ([Origin1Type], [Origin1Name]) REFERENCES [dbo].[ITModelObject] ([Type], [Name]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ITModelObjectAspect_Origin1Type_Origin1Name]
    ON [dbo].[ITModelObjectAspect]([Origin1Type] ASC, [Origin1Name] ASC);

