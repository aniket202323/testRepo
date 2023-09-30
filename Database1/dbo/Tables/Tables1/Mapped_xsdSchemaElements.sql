CREATE TABLE [dbo].[Mapped_xsdSchemaElements] (
    [ElementId]     BIGINT NOT NULL,
    [MappingTypeId] BIGINT NOT NULL,
    CONSTRAINT [Mapped_xsdSchemaElements_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC),
    CONSTRAINT [MappedxsdSchemaElements_FK_MappingTypes] FOREIGN KEY ([MappingTypeId]) REFERENCES [dbo].[Mapping_Types] ([MappingTypeId]),
    CONSTRAINT [MappedxsdSchemaElements_FK_xsdSchemaElements] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[xsdSchemaElements] ([ElementId]),
    CONSTRAINT [Mapped_xsdSchemaElements_UC_EIdMId] UNIQUE NONCLUSTERED ([MappingTypeId] ASC, [ElementId] ASC)
);

