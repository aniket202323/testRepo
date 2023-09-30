CREATE TABLE [dbo].[DisplayDmc] (
    [MainDisplayClass]                NVARCHAR (255)  NULL,
    [LocationPath]                    NVARCHAR (4000) NULL,
    [TechnologyType]                  NVARCHAR (255)  NULL,
    [SupportAsyncOperations]          BIT             NULL,
    [LastModified]                    DATETIME        NULL,
    [Metadata]                        IMAGE           NULL,
    [RequiresRebuild]                 BIT             NULL,
    [DisplayDmcDisplayHierarchyDmcId] NVARCHAR (255)  NOT NULL,
    [ModuleName]                      NVARCHAR (255)  NULL,
    [ProjectName]                     NVARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([DisplayDmcDisplayHierarchyDmcId] ASC),
    CONSTRAINT [DisplayDmc_ComponentModule_Relation1] FOREIGN KEY ([ModuleName]) REFERENCES [dbo].[ComponentModule] ([ModuleName]),
    CONSTRAINT [DisplayDmc_ComponentProject_Relation1] FOREIGN KEY ([ProjectName]) REFERENCES [dbo].[ComponentProject] ([ProjectName]),
    CONSTRAINT [DisplayDmc_DisplayHierarchyDmc_Relation1] FOREIGN KEY ([DisplayDmcDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayHierarchyDmc] ([DisplayHierarchyDmcId])
);


GO
CREATE NONCLUSTERED INDEX [NC_DisplayDmc_ModuleName]
    ON [dbo].[DisplayDmc]([ModuleName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_DisplayDmc_ProjectName]
    ON [dbo].[DisplayDmc]([ProjectName] ASC);

