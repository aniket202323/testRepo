CREATE TABLE [dbo].[Product_Dependency_Version] (
    [Product_Dependency_Version_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]                    INT           NULL,
    [Effective_Date]                DATETIME      NOT NULL,
    [Entry_On]                      DATETIME      NOT NULL,
    [Expiration_Date]               DATETIME      NULL,
    [Prod_Id]                       INT           NOT NULL,
    [User_Id]                       INT           NOT NULL,
    [Version]                       NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Product_Dependency_Version] PRIMARY KEY CLUSTERED ([Product_Dependency_Version_Id] ASC),
    CONSTRAINT [FK_Product_Dependency_Version_Products] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [FK_Product_Dependency_Version_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Dependency_Version_History_Del]
 ON  [dbo].[Product_Dependency_Version]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Dependency_Version_History
 	  	   (Comment_Id,Effective_Date,Entry_On,Expiration_Date,Prod_Id,Product_Dependency_Version_Id,User_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Effective_Date,a.Entry_On,a.Expiration_Date,a.Prod_Id,a.Product_Dependency_Version_Id,a.User_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Dependency_Version_History_Ins]
 ON  [dbo].[Product_Dependency_Version]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Dependency_Version_History
 	  	   (Comment_Id,Effective_Date,Entry_On,Expiration_Date,Prod_Id,Product_Dependency_Version_Id,User_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Effective_Date,a.Entry_On,a.Expiration_Date,a.Prod_Id,a.Product_Dependency_Version_Id,a.User_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Dependency_Version_History_Upd]
 ON  [dbo].[Product_Dependency_Version]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Dependency_Version_History
 	  	   (Comment_Id,Effective_Date,Entry_On,Expiration_Date,Prod_Id,Product_Dependency_Version_Id,User_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Effective_Date,a.Entry_On,a.Expiration_Date,a.Prod_Id,a.Product_Dependency_Version_Id,a.User_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
