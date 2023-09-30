CREATE TABLE [dbo].[Security_Items] (
    [Security_Item_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Security_Item_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [SecItems_PK_SecItemId] PRIMARY KEY NONCLUSTERED ([Security_Item_Id] ASC),
    CONSTRAINT [SecItems_UC_SecItemDesc] UNIQUE NONCLUSTERED ([Security_Item_Desc] ASC)
);

