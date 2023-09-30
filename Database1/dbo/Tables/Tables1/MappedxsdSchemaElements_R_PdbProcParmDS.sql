CREATE TABLE [dbo].[MappedxsdSchemaElements_R_PdbProcParmDS] (
    [ElementId] BIGINT         NOT NULL,
    [ParamName] NVARCHAR (128) NOT NULL,
    [ProcName]  NVARCHAR (128) NOT NULL,
    CONSTRAINT [MappedxsdSchemaElements_R_PdbProcParmDS_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC),
    CONSTRAINT [MappedxsdSchemaElements_R_PdbProcParmDS_FK_MappedxsdSchemaElements] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[Mapped_xsdSchemaElements] ([ElementId])
);

