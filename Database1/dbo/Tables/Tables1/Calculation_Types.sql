CREATE TABLE [dbo].[Calculation_Types] (
    [Calculation_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Calculation_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PK_Calculation_Types] PRIMARY KEY NONCLUSTERED ([Calculation_Type_Id] ASC)
);

