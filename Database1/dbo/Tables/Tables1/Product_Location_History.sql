CREATE TABLE [dbo].[Product_Location_History] (
    [Product_Location_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Entry_On]                    DATETIME     NULL,
    [Key_Id]                      INT          NULL,
    [Prod_Id]                     INT          NULL,
    [Table_Id]                    INT          NULL,
    [User_Id]                     INT          NULL,
    [Product_Location_Id]         INT          NULL,
    [Modified_On]                 DATETIME     NULL,
    [DBTT_Id]                     TINYINT      NULL,
    [Column_Updated_BitMask]      VARCHAR (15) NULL,
    CONSTRAINT [Product_Location_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Location_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductLocationHistory_IX_ProductLocationIdModifiedOn]
    ON [dbo].[Product_Location_History]([Product_Location_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Location_History_UpdDel]
 ON  [dbo].[Product_Location_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
