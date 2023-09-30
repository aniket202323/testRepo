CREATE TABLE [dbo].[Product_Family_History] (
    [Product_Family_History_Id] BIGINT                   IDENTITY (1, 1) NOT NULL,
    [Product_Family_Desc]       [dbo].[Varchar_Desc]     NULL,
    [Comment_Id]                INT                      NULL,
    [External_Link]             [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]                  INT                      NULL,
    [Product_Family_Id]         INT                      NULL,
    [Modified_On]               DATETIME                 NULL,
    [DBTT_Id]                   TINYINT                  NULL,
    [Column_Updated_BitMask]    VARCHAR (15)             NULL,
    CONSTRAINT [Product_Family_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Family_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductFamilyHistory_IX_ProductFamilyIdModifiedOn]
    ON [dbo].[Product_Family_History]([Product_Family_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Family_History_UpdDel]
 ON  [dbo].[Product_Family_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
