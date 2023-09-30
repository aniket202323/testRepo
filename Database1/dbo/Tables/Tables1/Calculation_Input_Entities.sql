CREATE TABLE [dbo].[Calculation_Input_Entities] (
    [Calc_Input_Entity_Id]    INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entity_Name]             [dbo].[Varchar_Desc] NOT NULL,
    [Locked]                  BIT                  CONSTRAINT [DF_Calculation_Input_Types_Locked] DEFAULT ((0)) NOT NULL,
    [Show_On_Input_Variables] TINYINT              CONSTRAINT [DF_CalculationInputEntities_ShowOnInputVariables_1] DEFAULT ((1)) NOT NULL,
    [Trigger_Type_Mask]       TINYINT              NULL,
    [User_Interface]          TINYINT              CONSTRAINT [DF__Calculati__User___2B3F6F97] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Calculation_Input_Entities] PRIMARY KEY NONCLUSTERED ([Calc_Input_Entity_Id] ASC)
);

