CREATE TABLE [dbo].[MappedxsdSchemaElements_R_PdbProcsDS] (
    [ElementId]    BIGINT         NOT NULL,
    [ProcName]     NVARCHAR (128) NOT NULL,
    [sequence_num] INT            NOT NULL,
    CONSTRAINT [MappedxsdSchemaElements_R_MessageSPsDS_PK_ElementId] PRIMARY KEY CLUSTERED ([ElementId] ASC),
    CONSTRAINT [MappedxsdSchemaElements_R_PdbProcsDS_FK_MappedxsdSchemaElements] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[Mapped_xsdSchemaElements] ([ElementId])
);

