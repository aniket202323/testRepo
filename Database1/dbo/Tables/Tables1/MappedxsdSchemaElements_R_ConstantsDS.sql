CREATE TABLE [dbo].[MappedxsdSchemaElements_R_ConstantsDS] (
    [Constant]  SQL_VARIANT NULL,
    [ElementId] BIGINT      NOT NULL,
    CONSTRAINT [MappedxsdSchemaElements_R_ConstantsDS_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC),
    CONSTRAINT [MappedxsdSchemaElements_R_ConstantsDS_FK_MappedxsdSchemaElements] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[Mapped_xsdSchemaElements] ([ElementId])
);

