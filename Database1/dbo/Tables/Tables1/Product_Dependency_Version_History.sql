CREATE TABLE [dbo].[Product_Dependency_Version_History] (
    [Product_Dependency_Version_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Effective_Date]                        DATETIME      NULL,
    [Entry_On]                              DATETIME      NULL,
    [Prod_Id]                               INT           NULL,
    [User_Id]                               INT           NULL,
    [Version]                               NVARCHAR (50) NULL,
    [Comment_Id]                            INT           NULL,
    [Expiration_Date]                       DATETIME      NULL,
    [Product_Dependency_Version_Id]         INT           NULL,
    [Modified_On]                           DATETIME      NULL,
    [DBTT_Id]                               TINYINT       NULL,
    [Column_Updated_BitMask]                VARCHAR (15)  NULL,
    CONSTRAINT [Product_Dependency_Version_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Dependency_Version_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductDependencyVersionHistory_IX_ProductDependencyVersionIdModifiedOn]
    ON [dbo].[Product_Dependency_Version_History]([Product_Dependency_Version_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Dependency_Version_History_UpdDel]
 ON  [dbo].[Product_Dependency_Version_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
