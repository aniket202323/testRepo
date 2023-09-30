CREATE TABLE [dbo].[SolutionLensDmc] (
    [Version]               BIGINT         NULL,
    [SolutionSolutionDmcId] NVARCHAR (255) NOT NULL,
    [LensLensDmcId]         NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([SolutionSolutionDmcId] ASC, [LensLensDmcId] ASC),
    CONSTRAINT [SolutionLensDmc_LensDmc_Relation1] FOREIGN KEY ([LensLensDmcId]) REFERENCES [dbo].[LensDmc] ([LensDmcId]),
    CONSTRAINT [SolutionLensDmc_SolutionDmc_Relation1] FOREIGN KEY ([SolutionSolutionDmcId]) REFERENCES [dbo].[SolutionDmc] ([SolutionDmcId])
);


GO
CREATE NONCLUSTERED INDEX [NC_SolutionLensDmc_LensLensDmcId]
    ON [dbo].[SolutionLensDmc]([LensLensDmcId] ASC);

