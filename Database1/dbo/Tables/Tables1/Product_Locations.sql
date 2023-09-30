CREATE TABLE [dbo].[Product_Locations] (
    [Product_Location_Id] INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]            DATETIME NOT NULL,
    [Key_Id]              INT      NOT NULL,
    [Prod_Id]             INT      NOT NULL,
    [Table_Id]            INT      NOT NULL,
    [User_Id]             INT      NOT NULL,
    CONSTRAINT [PK_Product_Locaitons] PRIMARY KEY CLUSTERED ([Product_Location_Id] ASC),
    CONSTRAINT [FK_Product_Locations_Products] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [FK_Product_Locations_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Locations_History_Del]
 ON  [dbo].[Product_Locations]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Location_History
 	  	   (Entry_On,Key_Id,Prod_Id,Product_Location_Id,Table_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Key_Id,a.Prod_Id,a.Product_Location_Id,a.Table_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Locations_History_Ins]
 ON  [dbo].[Product_Locations]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Location_History
 	  	   (Entry_On,Key_Id,Prod_Id,Product_Location_Id,Table_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Key_Id,a.Prod_Id,a.Product_Location_Id,a.Table_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Locations_History_Upd]
 ON  [dbo].[Product_Locations]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Location_History
 	  	   (Entry_On,Key_Id,Prod_Id,Product_Location_Id,Table_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Key_Id,a.Prod_Id,a.Product_Location_Id,a.Table_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
