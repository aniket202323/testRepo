CREATE TABLE [dbo].[SPC_Group_Variable_Types] (
    [SPC_Group_Variable_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SPC_Group_Variable_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [SPC_Group_Variable_Types_PK_SPC_Group_Variable_Type_Id] PRIMARY KEY CLUSTERED ([SPC_Group_Variable_Type_Id] ASC)
);

