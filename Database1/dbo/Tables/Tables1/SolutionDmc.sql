CREATE TABLE [dbo].[SolutionDmc] (
    [Name]           NVARCHAR (255) NULL,
    [DisplayName]    NVARCHAR (255) NULL,
    [Type]           NVARCHAR (255) NULL,
    [SolutionDmcId]  NVARCHAR (255) NOT NULL,
    [r_Public]       BIT            NULL,
    [IconID]         NVARCHAR (255) NULL,
    [Classification] NVARCHAR (255) NULL,
    [Description]    NVARCHAR (255) NULL,
    [Version]        BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([SolutionDmcId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SolutionDmc_Name_Type]
    ON [dbo].[SolutionDmc]([Name] ASC, [Type] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SolutionDmc_DisplayName_Type]
    ON [dbo].[SolutionDmc]([DisplayName] ASC, [Type] ASC);

