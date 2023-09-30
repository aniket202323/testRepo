CREATE TABLE [dbo].[Product_Properties_History] (
    [Product_Properties_History_Id] BIGINT                   IDENTITY (1, 1) NOT NULL,
    [Prop_Desc]                     [dbo].[Varchar_Desc]     NULL,
    [Auto_Sync_Chars]               TINYINT                  NULL,
    [Comment_Id]                    INT                      NULL,
    [Default_Size]                  REAL                     NULL,
    [Eng_Units]                     VARCHAR (50)             NULL,
    [External_Link]                 [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]                      INT                      NULL,
    [Is_Hidden]                     TINYINT                  NULL,
    [Is_Unit_Specific]              TINYINT                  NULL,
    [Product_Family_Id]             INT                      NULL,
    [Property_Order]                INT                      NULL,
    [PU_Id]                         INT                      NULL,
    [Tag]                           VARCHAR (50)             NULL,
    [Property_Type_Id]              INT                      NULL,
    [Prop_Id]                       INT                      NULL,
    [Modified_On]                   DATETIME                 NULL,
    [DBTT_Id]                       TINYINT                  NULL,
    [Column_Updated_BitMask]        VARCHAR (15)             NULL,
    CONSTRAINT [Product_Properties_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Properties_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductPropertiesHistory_IX_PropIdModifiedOn]
    ON [dbo].[Product_Properties_History]([Prop_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Properties_History_UpdDel]
 ON  [dbo].[Product_Properties_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
