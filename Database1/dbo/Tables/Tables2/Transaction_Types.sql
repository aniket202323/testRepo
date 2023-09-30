CREATE TABLE [dbo].[Transaction_Types] (
    [Trans_Type_Id] INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Trans_Desc]    [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [TransTypes_PK_TransTypeId] PRIMARY KEY CLUSTERED ([Trans_Type_Id] ASC)
);

