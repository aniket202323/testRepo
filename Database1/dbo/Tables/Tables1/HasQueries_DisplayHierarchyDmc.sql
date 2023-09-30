CREATE TABLE [dbo].[HasQueries_DisplayHierarchyDmc] (
    [r_Order]                           INT            NULL,
    [Version]                           BIGINT         NULL,
    [QueryId]                           NVARCHAR (255) NOT NULL,
    [DomainObjectDisplayHierarchyDmcId] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([QueryId] ASC, [DomainObjectDisplayHierarchyDmcId] ASC),
    CONSTRAINT [HasQueries_DisplayHierarchyDmc_DisplayHierarchyDmc_Relation1] FOREIGN KEY ([DomainObjectDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayHierarchyDmc] ([DisplayHierarchyDmcId]),
    CONSTRAINT [HasQueries_DisplayHierarchyDmc_QueryDmc_Relation1] FOREIGN KEY ([QueryId]) REFERENCES [dbo].[QueryDmc] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_HasQueries_DisplayHierarchyDmc_DomainObjectDisplayHierarchyDmcId]
    ON [dbo].[HasQueries_DisplayHierarchyDmc]([DomainObjectDisplayHierarchyDmcId] ASC);

