CREATE TABLE [dbo].[Product_Dependencies] (
    [Product_Dependency_Id]         INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dependency_Id]                 INT      NOT NULL,
    [Designated_Product_Id]         INT      NOT NULL,
    [Entry_On]                      DATETIME NOT NULL,
    [Product_Dependency_Version_Id] INT      NOT NULL,
    [User_Id]                       INT      NOT NULL,
    CONSTRAINT [PK_Product_Dependencies] PRIMARY KEY CLUSTERED ([Product_Dependency_Id] ASC),
    CONSTRAINT [FK_Product_Dependencies_Dependencies] FOREIGN KEY ([Dependency_Id]) REFERENCES [dbo].[Dependencies] ([Dependency_Id]),
    CONSTRAINT [FK_Product_Dependencies_Product_Dependency_Version] FOREIGN KEY ([Product_Dependency_Version_Id]) REFERENCES [dbo].[Product_Dependency_Version] ([Product_Dependency_Version_Id]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_Product_Dependencies_Products] FOREIGN KEY ([Designated_Product_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [FK_Product_Dependencies_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Dependencies_History_Del]
 ON  [dbo].[Product_Dependencies]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Dependency_History
 	  	   (Dependency_Id,Designated_Product_Id,Entry_On,Product_Dependency_Id,Product_Dependency_Version_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Id,a.Designated_Product_Id,a.Entry_On,a.Product_Dependency_Id,a.Product_Dependency_Version_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Dependencies_History_Ins]
 ON  [dbo].[Product_Dependencies]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Dependency_History
 	  	   (Dependency_Id,Designated_Product_Id,Entry_On,Product_Dependency_Id,Product_Dependency_Version_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Id,a.Designated_Product_Id,a.Entry_On,a.Product_Dependency_Id,a.Product_Dependency_Version_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Dependencies_History_Upd]
 ON  [dbo].[Product_Dependencies]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Dependency_History
 	  	   (Dependency_Id,Designated_Product_Id,Entry_On,Product_Dependency_Id,Product_Dependency_Version_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Id,a.Designated_Product_Id,a.Entry_On,a.Product_Dependency_Id,a.Product_Dependency_Version_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
