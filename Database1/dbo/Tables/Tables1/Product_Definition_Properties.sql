CREATE TABLE [dbo].[Product_Definition_Properties] (
    [Product_Definition_Property_Id]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data_Type_Id]                     INT            NOT NULL,
    [Entry_On]                         DATETIME       NOT NULL,
    [Product_Definition_Property_Desc] NVARCHAR (300) NOT NULL,
    [Spec_Id]                          INT            NULL,
    [User_Id]                          INT            NOT NULL,
    CONSTRAINT [PK_Product_Definition_Properties] PRIMARY KEY CLUSTERED ([Product_Definition_Property_Id] ASC),
    CONSTRAINT [FK_Product_Definition_Properties_Data_Type] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id]),
    CONSTRAINT [FK_Product_Definition_Properties_Specifications] FOREIGN KEY ([Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [FK_Product_Definition_Properties_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Definition_Properties_History_Upd]
 ON  [dbo].[Product_Definition_Properties]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Definition_Property_History
 	  	   (Data_Type_Id,Entry_On,Product_Definition_Property_Desc,Product_Definition_Property_Id,Spec_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Data_Type_Id,a.Entry_On,a.Product_Definition_Property_Desc,a.Product_Definition_Property_Id,a.Spec_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Definition_Properties_History_Ins]
 ON  [dbo].[Product_Definition_Properties]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Definition_Property_History
 	  	   (Data_Type_Id,Entry_On,Product_Definition_Property_Desc,Product_Definition_Property_Id,Spec_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Data_Type_Id,a.Entry_On,a.Product_Definition_Property_Desc,a.Product_Definition_Property_Id,a.Spec_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Definition_Properties_History_Del]
 ON  [dbo].[Product_Definition_Properties]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Definition_Property_History
 	  	   (Data_Type_Id,Entry_On,Product_Definition_Property_Desc,Product_Definition_Property_Id,Spec_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Data_Type_Id,a.Entry_On,a.Product_Definition_Property_Desc,a.Product_Definition_Property_Id,a.Spec_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
