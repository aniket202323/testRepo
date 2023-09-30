CREATE TABLE [dbo].[Product_Definition_History] (
    [Product_Definition_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Effective_Date]                DATETIME       NULL,
    [Entry_On]                      DATETIME       NULL,
    [Product_Definition_Name]       NVARCHAR (100) NULL,
    [Production_Rule_Id]            INT            NULL,
    [User_Id]                       INT            NULL,
    [IsReleased]                    INT            NULL,
    [Version]                       NVARCHAR (50)  NULL,
    [Char_Id]                       INT            NULL,
    [Comment_Id]                    INT            NULL,
    [Expiration_Date]               DATETIME       NULL,
    [Product_Definition_Desc]       NVARCHAR (300) NULL,
    [Product_Definition_Id]         INT            NULL,
    [Modified_On]                   DATETIME       NULL,
    [DBTT_Id]                       TINYINT        NULL,
    [Column_Updated_BitMask]        VARCHAR (15)   NULL,
    CONSTRAINT [Product_Definition_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Definition_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductDefinitionHistory_IX_ProductDefinitionIdModifiedOn]
    ON [dbo].[Product_Definition_History]([Product_Definition_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Definition_History_UpdDel]
 ON  [dbo].[Product_Definition_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
