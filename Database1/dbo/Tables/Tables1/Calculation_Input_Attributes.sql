CREATE TABLE [dbo].[Calculation_Input_Attributes] (
    [Calc_Input_Attribute_Id] INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Attribute_Name]          [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PK_Calculation_Input_Attributes] PRIMARY KEY NONCLUSTERED ([Calc_Input_Attribute_Id] ASC)
);

