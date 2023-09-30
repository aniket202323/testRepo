CREATE TABLE [dbo].[ConfigPanelMethod] (
    [MethodId]                        NVARCHAR (255) NOT NULL,
    [ConfigPanelVersion]              BIGINT         NULL,
    [Version]                         BIGINT         NULL,
    [DisplayDmcDisplayHierarchyDmcId] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([MethodId] ASC),
    CONSTRAINT [ConfigPanelMethod_DisplayDmc_Relation1] FOREIGN KEY ([DisplayDmcDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayDmc] ([DisplayDmcDisplayHierarchyDmcId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ConfigPanelMethod_DisplayDmcDisplayHierarchyDmcId]
    ON [dbo].[ConfigPanelMethod]([DisplayDmcDisplayHierarchyDmcId] ASC);

