CREATE TABLE [dbo].[HasQueries_SolutionDmc] (
    [r_Order]                   INT            NULL,
    [Version]                   BIGINT         NULL,
    [QueryId]                   NVARCHAR (255) NOT NULL,
    [DomainObjectSolutionDmcId] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([QueryId] ASC, [DomainObjectSolutionDmcId] ASC),
    CONSTRAINT [HasQueries_SolutionDmc_QueryDmc_Relation1] FOREIGN KEY ([QueryId]) REFERENCES [dbo].[QueryDmc] ([Id]),
    CONSTRAINT [HasQueries_SolutionDmc_SolutionDmc_Relation1] FOREIGN KEY ([DomainObjectSolutionDmcId]) REFERENCES [dbo].[SolutionDmc] ([SolutionDmcId])
);

