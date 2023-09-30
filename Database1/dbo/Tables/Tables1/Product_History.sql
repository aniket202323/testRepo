CREATE TABLE [dbo].[Product_History] (
    [Product_History_Id]              BIGINT                    IDENTITY (1, 1) NOT NULL,
    [Prod_Code]                       [dbo].[Varchar_Prod_Code] NULL,
    [Prod_Desc]                       [dbo].[Varchar_Desc]      NULL,
    [Alias_For_Product]               INT                       NULL,
    [Comment_Id]                      INT                       NULL,
    [Event_Esignature_Level]          INT                       NULL,
    [Extended_Info]                   VARCHAR (255)             NULL,
    [External_Link]                   [dbo].[Varchar_Ext_Link]  NULL,
    [Is_Active_Product]               TINYINT                   NULL,
    [Is_Manufacturing_Product]        TINYINT                   NULL,
    [Is_Sales_Product]                TINYINT                   NULL,
    [Product_Change_Esignature_Level] INT                       NULL,
    [Tag]                             VARCHAR (50)              NULL,
    [Use_Manufacturing_Product]       INT                       NULL,
    [Product_Family_Id]               INT                       NULL,
    [Prod_Id]                         INT                       NULL,
    [Modified_On]                     DATETIME                  NULL,
    [DBTT_Id]                         TINYINT                   NULL,
    [Column_Updated_BitMask]          VARCHAR (15)              NULL,
    CONSTRAINT [Product_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductHistory_IX_ProdIdModifiedOn]
    ON [dbo].[Product_History]([Prod_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_History_UpdDel]
 ON  [dbo].[Product_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
