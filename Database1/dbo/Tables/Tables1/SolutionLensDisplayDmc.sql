CREATE TABLE [dbo].[SolutionLensDisplayDmc] (
    [Version]                                BIGINT         NULL,
    [SolutionLensSolutionSolutionDmcId]      NVARCHAR (255) NOT NULL,
    [SolutionLensLensLensDmcId]              NVARCHAR (255) NOT NULL,
    [DisplayDisplayDmcDisplayHierarchyDmcId] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([SolutionLensSolutionSolutionDmcId] ASC, [SolutionLensLensLensDmcId] ASC, [DisplayDisplayDmcDisplayHierarchyDmcId] ASC),
    CONSTRAINT [SolutionLensDisplayDmc_DisplayDmc_Relation1] FOREIGN KEY ([DisplayDisplayDmcDisplayHierarchyDmcId]) REFERENCES [dbo].[DisplayDmc] ([DisplayDmcDisplayHierarchyDmcId]),
    CONSTRAINT [SolutionLensDisplayDmc_SolutionLensDmc_Relation1] FOREIGN KEY ([SolutionLensSolutionSolutionDmcId], [SolutionLensLensLensDmcId]) REFERENCES [dbo].[SolutionLensDmc] ([SolutionSolutionDmcId], [LensLensDmcId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SolutionLensDisplayDmc_DisplayDisplayDmcDisplayHierarchyDmcId]
    ON [dbo].[SolutionLensDisplayDmc]([DisplayDisplayDmcDisplayHierarchyDmcId] ASC);

