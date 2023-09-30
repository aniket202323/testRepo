CREATE TABLE [dbo].[DataTypeCustomEditorDmfc] (
    [DataTypeColumn]               NVARCHAR (255) NOT NULL,
    [DataTypeAssemblyColumn]       NVARCHAR (255) NULL,
    [DataTypeEditorColumn]         NVARCHAR (255) NULL,
    [DataTypeEditorAssemblyColumn] NVARCHAR (255) NULL,
    [Version]                      BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([DataTypeColumn] ASC)
);

