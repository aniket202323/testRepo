CREATE TABLE [dbo].[xsdSchemaElements] (
    [ElementId]       BIGINT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ElementName]     NVARCHAR (50) NOT NULL,
    [ElementType]     BIGINT        NOT NULL,
    [ParentElementId] BIGINT        NULL,
    [SchemaName]      NVARCHAR (50) NOT NULL,
    CONSTRAINT [xsdSchemaElements_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC),
    CONSTRAINT [xsdSchemaElements_FK_xsdSchemaElements] FOREIGN KEY ([ParentElementId]) REFERENCES [dbo].[xsdSchemaElements] ([ElementId]),
    CONSTRAINT [xsdSchemaElements_UC_SchemaElementNameParent] UNIQUE NONCLUSTERED ([SchemaName] ASC, [ElementName] ASC, [ParentElementId] ASC)
);

