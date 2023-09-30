CREATE TABLE [dbo].[MappedxsdSchemaElements_R_PdbTableColumnDS] (
    [ColumnName] NVARCHAR (50) NOT NULL,
    [ElementId]  BIGINT        NOT NULL,
    [TableName]  NVARCHAR (50) NOT NULL,
    CONSTRAINT [MappedxsdSchemaElements_R_PdbTableColunDS_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC, [TableName] ASC, [ColumnName] ASC),
    CONSTRAINT [MappedxsdSchemaElements_R_PdbTablesColumnsDS_FK_MappedxsdSchemaElements] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[Mapped_xsdSchemaElements] ([ElementId])
);

