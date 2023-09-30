CREATE TABLE [dbo].[PdbProcsDS_R_PdbParmXpathDS] (
    [ElementId] BIGINT          NOT NULL,
    [ParamName] NVARCHAR (128)  NOT NULL,
    [xPathExpr] NVARCHAR (1000) NOT NULL,
    CONSTRAINT [PdbProcsDS_R_PdbParmXpathDS_PK_ElementIdParamId] PRIMARY KEY CLUSTERED ([ElementId] ASC, [ParamName] ASC),
    CONSTRAINT [PdbProcsDS_R_PdbParmXpathDS_FK_MappedxsdSchemaElements_R_PdbProcsDS] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[MappedxsdSchemaElements_R_PdbProcsDS] ([ElementId])
);

