CREATE TABLE [dbo].[ParametersDmfc] (
    [KeyColumn]                       NVARCHAR (255) NOT NULL,
    [ParameterType]                   NVARCHAR (255) NULL,
    [Name]                            NVARCHAR (255) NULL,
    [DisplayName]                     NVARCHAR (255) NULL,
    [Description]                     NVARCHAR (255) NULL,
    [DataType]                        NVARCHAR (255) NULL,
    [DefaultValue]                    IMAGE          NULL,
    [CanUpdate]                       BIT            NULL,
    [AvailableDataQuery]              NVARCHAR (255) NULL,
    [ValidClassificationExpression]   NVARCHAR (255) NULL,
    [InvalidClassificationExpression] NVARCHAR (255) NULL,
    [ModelFilters]                    NVARCHAR (255) NULL,
    [ModelFilterType]                 NVARCHAR (255) NULL,
    [EntryPointFilters]               NVARCHAR (255) NULL,
    [EntryPointFilterType]            NVARCHAR (255) NULL,
    [Version]                         BIGINT         NULL,
    [DisplayDmcDisplayHierarchyDmcId] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([KeyColumn] ASC),
    CONSTRAINT [ParametersDmfc_DisplayDmc_Relation1] FOREIGN KEY ([DisplayDmcDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayDmc] ([DisplayDmcDisplayHierarchyDmcId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ParametersDmfc_DisplayDmcDisplayHierarchyDmcId]
    ON [dbo].[ParametersDmfc]([DisplayDmcDisplayHierarchyDmcId] ASC);

