CREATE TABLE [dbo].[DisplayHierarchyDmc] (
    [Name]                        NVARCHAR (255) NULL,
    [DisplayName]                 NVARCHAR (255) NULL,
    [Type]                        NVARCHAR (255) NULL,
    [DisplayHierarchyDmcId]       NVARCHAR (255) NOT NULL,
    [r_Public]                    BIT            NULL,
    [IconID]                      NVARCHAR (255) NULL,
    [Classification]              NVARCHAR (255) NULL,
    [Description]                 NVARCHAR (255) NULL,
    [Version]                     BIGINT         NULL,
    [ParentDisplayHierarchyDmcId] NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([DisplayHierarchyDmcId] ASC),
    CONSTRAINT [DisplayHierarchyDmc_DisplayHierarchyDmc_Relation1] FOREIGN KEY ([ParentDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayHierarchyDmc] ([DisplayHierarchyDmcId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DisplayHierarchyDmc_ParentDisplayHierarchyDmcId_DisplayName_Type]
    ON [dbo].[DisplayHierarchyDmc]([ParentDisplayHierarchyDmcId] ASC, [DisplayName] ASC, [Type] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DisplayHierarchyDmc_Name_Type]
    ON [dbo].[DisplayHierarchyDmc]([Name] ASC, [Type] ASC);

