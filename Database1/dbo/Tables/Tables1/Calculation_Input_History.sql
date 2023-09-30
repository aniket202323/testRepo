CREATE TABLE [dbo].[Calculation_Input_History] (
    [Calculation_Input_History_Id] BIGINT               IDENTITY (1, 1) NOT NULL,
    [Alias]                        [dbo].[Varchar_Desc] NULL,
    [Calc_Input_Attribute_Id]      INT                  NULL,
    [Calc_Input_Entity_Id]         INT                  NULL,
    [Calc_Input_Order]             INT                  NULL,
    [Calculation_Id]               INT                  NULL,
    [Input_Name]                   [dbo].[Varchar_Desc] NULL,
    [Non_Triggering]               BIT                  NULL,
    [Optional]                     BIT                  NULL,
    [Default_Value]                VARCHAR (1000)       NULL,
    [Calc_Input_Id]                INT                  NULL,
    [Modified_On]                  DATETIME             NULL,
    [DBTT_Id]                      TINYINT              NULL,
    [Column_Updated_BitMask]       VARCHAR (15)         NULL,
    CONSTRAINT [Calculation_Input_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Calculation_Input_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CalculationInputHistory_IX_CalcInputIdModifiedOn]
    ON [dbo].[Calculation_Input_History]([Calc_Input_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Calculation_Input_History_UpdDel]
 ON  [dbo].[Calculation_Input_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
