CREATE TABLE [dbo].[Data_Type] (
    [Data_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    [Use_Precision]  BIT                  CONSTRAINT [Data_Type_DF_Precision] DEFAULT ((0)) NOT NULL,
    [User_Defined]   BIT                  CONSTRAINT [Data_Type_DF_UserDefined] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [Data_Type_PK_DataTypeId] PRIMARY KEY CLUSTERED ([Data_Type_Id] ASC)
);

