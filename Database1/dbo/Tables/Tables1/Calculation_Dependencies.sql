CREATE TABLE [dbo].[Calculation_Dependencies] (
    [Calc_Dependency_Id]       INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Calc_Dependency_Scope_Id] INT                  NOT NULL,
    [Calculation_Id]           INT                  NOT NULL,
    [Name]                     [dbo].[Varchar_Desc] NOT NULL,
    [Optional]                 BIT                  NOT NULL,
    CONSTRAINT [PK_Calculation_Dependencies] PRIMARY KEY NONCLUSTERED ([Calc_Dependency_Id] ASC),
    CONSTRAINT [FK_Calculation_Dependencies_Calculation_Dependency_Scopes] FOREIGN KEY ([Calc_Dependency_Scope_Id]) REFERENCES [dbo].[Calculation_Dependency_Scopes] ([Calc_Dependency_Scope_Id]),
    CONSTRAINT [FK_Calculation_Dependencies_Calculations] FOREIGN KEY ([Calculation_Id]) REFERENCES [dbo].[Calculations] ([Calculation_Id])
);


GO
CREATE NONCLUSTERED INDEX [CalculationDependencies_IDX_CalcDepId]
    ON [dbo].[Calculation_Dependencies]([Calc_Dependency_Id] ASC);

