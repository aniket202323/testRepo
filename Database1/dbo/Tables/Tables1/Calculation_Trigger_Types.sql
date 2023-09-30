CREATE TABLE [dbo].[Calculation_Trigger_Types] (
    [Trigger_Type_Id] INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]            [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PK_Calculation_Trigger_Types] PRIMARY KEY NONCLUSTERED ([Trigger_Type_Id] ASC)
);

