CREATE TABLE [dbo].[SPC_Calculation_Types] (
    [SPC_Calculation_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SPC_Calculation_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [SPC_Calculation_Types_PK_SPC_Calculation_Type_Id] PRIMARY KEY CLUSTERED ([SPC_Calculation_Type_Id] ASC)
);

