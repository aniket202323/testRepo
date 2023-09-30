CREATE TABLE [dbo].[Product_Dependency_History] (
    [Product_Dependency_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Dependency_Id]                 INT          NULL,
    [Designated_Product_Id]         INT          NULL,
    [Entry_On]                      DATETIME     NULL,
    [Product_Dependency_Version_Id] INT          NULL,
    [User_Id]                       INT          NULL,
    [Product_Dependency_Id]         INT          NULL,
    [Modified_On]                   DATETIME     NULL,
    [DBTT_Id]                       TINYINT      NULL,
    [Column_Updated_BitMask]        VARCHAR (15) NULL,
    CONSTRAINT [Product_Dependency_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Dependency_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductDependencyHistory_IX_ProductDependencyIdModifiedOn]
    ON [dbo].[Product_Dependency_History]([Product_Dependency_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Dependency_History_UpdDel]
 ON  [dbo].[Product_Dependency_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
