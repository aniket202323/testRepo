CREATE TABLE [dbo].[Calculation_Instance_Dependencies_History] (
    [Calculation_Instance_Dependencies_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Calc_Dependency_Scope_Id]                     INT          NULL,
    [Result_Var_Id]                                INT          NULL,
    [Var_Id]                                       INT          NULL,
    [Calc_Dependency_NotActive]                    TINYINT      NULL,
    [Modified_On]                                  DATETIME     NULL,
    [DBTT_Id]                                      TINYINT      NULL,
    [Column_Updated_BitMask]                       VARCHAR (15) NULL,
    CONSTRAINT [Calculation_Instance_Dependencies_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Calculation_Instance_Dependencies_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CalculationInstanceDependenciesHistory_IX_ResultVarIdVarIdModifiedOn]
    ON [dbo].[Calculation_Instance_Dependencies_History]([Result_Var_Id] ASC, [Var_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Calculation_Instance_Dependencies_History_UpdDel]
 ON  [dbo].[Calculation_Instance_Dependencies_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
