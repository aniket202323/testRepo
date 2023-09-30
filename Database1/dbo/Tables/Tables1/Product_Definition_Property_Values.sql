CREATE TABLE [dbo].[Product_Definition_Property_Values] (
    [PDP_Value_Id]                   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]                       DATETIME      NOT NULL,
    [Product_Definition_Id]          INT           NOT NULL,
    [Product_Definition_Property_Id] INT           NOT NULL,
    [User_Id]                        INT           NOT NULL,
    [Value]                          NVARCHAR (50) NULL,
    CONSTRAINT [PK_Product_Definition_Property_Values] PRIMARY KEY CLUSTERED ([PDP_Value_Id] ASC),
    CONSTRAINT [FK_Product_Definition_Property_Values_Product_Definition_Properties] FOREIGN KEY ([Product_Definition_Property_Id]) REFERENCES [dbo].[Product_Definition_Properties] ([Product_Definition_Property_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Product_Definition_Property_Values_Product_Definitions] FOREIGN KEY ([Product_Definition_Id]) REFERENCES [dbo].[Product_Definitions] ([Product_Definition_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Product_Definition_Property_Values_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Definition_Property_Values_History_Del]
 ON  [dbo].[Product_Definition_Property_Values]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Definition_Property_Value_History
 	  	   (Entry_On,PDP_Value_Id,Product_Definition_Id,Product_Definition_Property_Id,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.PDP_Value_Id,a.Product_Definition_Id,a.Product_Definition_Property_Id,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Definition_Property_Values_History_Upd]
 ON  [dbo].[Product_Definition_Property_Values]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Definition_Property_Value_History
 	  	   (Entry_On,PDP_Value_Id,Product_Definition_Id,Product_Definition_Property_Id,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.PDP_Value_Id,a.Product_Definition_Id,a.Product_Definition_Property_Id,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Definition_Property_Values_History_Ins]
 ON  [dbo].[Product_Definition_Property_Values]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Definition_Property_Value_History
 	  	   (Entry_On,PDP_Value_Id,Product_Definition_Id,Product_Definition_Property_Id,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.PDP_Value_Id,a.Product_Definition_Id,a.Product_Definition_Property_Id,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
