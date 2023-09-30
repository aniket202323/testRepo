CREATE TABLE [dbo].[Calculation_Input_Data_History] (
    [Calculation_Input_Data_History_Id] BIGINT               IDENTITY (1, 1) NOT NULL,
    [Calc_Input_Id]                     INT                  NULL,
    [Result_Var_Id]                     INT                  NULL,
    [Alias_Name]                        VARCHAR (50)         NULL,
    [Default_Value]                     VARCHAR (1000)       NULL,
    [Input_Name]                        [dbo].[Varchar_Desc] NULL,
    [Member_Var_Id]                     INT                  NULL,
    [PU_Id]                             INT                  NULL,
    [Modified_On]                       DATETIME             NULL,
    [DBTT_Id]                           TINYINT              NULL,
    [Column_Updated_BitMask]            VARCHAR (15)         NULL,
    CONSTRAINT [Calculation_Input_Data_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Calculation_Input_Data_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CalculationInputDataHistory_IX_CalcInputIdModifiedOn]
    ON [dbo].[Calculation_Input_Data_History]([Calc_Input_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Calculation_Input_Data_History_UpdDel]
 ON  [dbo].[Calculation_Input_Data_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Calculation_Input_Data_History
 	 FROM Calculation_Input_Data_History a 
 	 JOIN  Deleted b on b.Calc_Input_Id = a.Calc_Input_Id
 	 and b.Result_Var_Id = a.Result_Var_Id
END
