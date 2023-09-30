CREATE TABLE [dbo].[Calculation_Dependency_Scopes] (
    [Calc_Dependency_Scope_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Calc_Dependency_Scope_Name] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PK_Calculation_Dependency_Scopes] PRIMARY KEY NONCLUSTERED ([Calc_Dependency_Scope_Id] ASC)
);

