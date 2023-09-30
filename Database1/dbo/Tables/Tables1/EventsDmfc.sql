CREATE TABLE [dbo].[EventsDmfc] (
    [KeyColumn]                       NVARCHAR (255) NOT NULL,
    [Name]                            NVARCHAR (255) NULL,
    [DisplayName]                     NVARCHAR (255) NULL,
    [Description]                     NVARCHAR (255) NULL,
    [Version]                         BIGINT         NULL,
    [DisplayDmcDisplayHierarchyDmcId] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([KeyColumn] ASC),
    CONSTRAINT [EventsDmfc_DisplayDmc_Relation1] FOREIGN KEY ([DisplayDmcDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayDmc] ([DisplayDmcDisplayHierarchyDmcId])
);


GO
CREATE NONCLUSTERED INDEX [NC_EventsDmfc_DisplayDmcDisplayHierarchyDmcId]
    ON [dbo].[EventsDmfc]([DisplayDmcDisplayHierarchyDmcId] ASC);

