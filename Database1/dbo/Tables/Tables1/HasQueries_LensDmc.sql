CREATE TABLE [dbo].[HasQueries_LensDmc] (
    [r_Order]               INT            NULL,
    [Version]               BIGINT         NULL,
    [QueryId]               NVARCHAR (255) NOT NULL,
    [DomainObjectLensDmcId] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([QueryId] ASC, [DomainObjectLensDmcId] ASC),
    CONSTRAINT [HasQueries_LensDmc_LensDmc_Relation1] FOREIGN KEY ([DomainObjectLensDmcId]) REFERENCES [dbo].[LensDmc] ([LensDmcId]),
    CONSTRAINT [HasQueries_LensDmc_QueryDmc_Relation1] FOREIGN KEY ([QueryId]) REFERENCES [dbo].[QueryDmc] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_HasQueries_LensDmc_DomainObjectLensDmcId]
    ON [dbo].[HasQueries_LensDmc]([DomainObjectLensDmcId] ASC);

