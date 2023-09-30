CREATE TABLE [dbo].[Property_Types] (
    [Property_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Property_Type_Data] INT                  NULL,
    [Property_Type_Name] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [PropertyTypes_PK_PropertyTypeId] PRIMARY KEY CLUSTERED ([Property_Type_Id] ASC)
);

