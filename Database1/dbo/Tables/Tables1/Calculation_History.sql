CREATE TABLE [dbo].[Calculation_History] (
    [Calculation_History_Id] BIGINT               IDENTITY (1, 1) NOT NULL,
    [Calculation_Desc]       VARCHAR (255)        NULL,
    [Calculation_Name]       VARCHAR (255)        NULL,
    [Calculation_Type_Id]    INT                  NULL,
    [Version]                VARCHAR (10)         NULL,
    [Locked]                 BIT                  NULL,
    [Optimize_Calc_Runs]     BIT                  NULL,
    [Trigger_Type_Id]        INT                  NULL,
    [Comment_Id]             INT                  NULL,
    [Equation]               VARCHAR (255)        NULL,
    [Lag_Time]               INT                  NULL,
    [Stored_Procedure_Name]  [dbo].[Varchar_Desc] NULL,
    [System_Calculation]     INT                  NULL,
    [Max_Run_Time]           INT                  NULL,
    [Calculation_Id]         INT                  NULL,
    [Modified_On]            DATETIME             NULL,
    [DBTT_Id]                TINYINT              NULL,
    [Column_Updated_BitMask] VARCHAR (15)         NULL,
    CONSTRAINT [Calculation_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Calculation_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CalculationHistory_IX_CalculationIdModifiedOn]
    ON [dbo].[Calculation_History]([Calculation_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Calculation_History_UpdDel]
 ON  [dbo].[Calculation_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
