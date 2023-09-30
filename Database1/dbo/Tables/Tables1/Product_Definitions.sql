CREATE TABLE [dbo].[Product_Definitions] (
    [Product_Definition_Id]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Char_Id]                 INT            NULL,
    [Comment_Id]              INT            NULL,
    [Effective_Date]          DATETIME       NOT NULL,
    [Entry_On]                DATETIME       NOT NULL,
    [Expiration_Date]         DATETIME       NULL,
    [IsReleased]              INT            CONSTRAINT [DF_Product_Definitions_IsReleased] DEFAULT ((0)) NOT NULL,
    [Product_Definition_Desc] NVARCHAR (300) NULL,
    [Product_Definition_Name] NVARCHAR (100) NOT NULL,
    [Production_Rule_Id]      INT            NOT NULL,
    [User_Id]                 INT            NOT NULL,
    [Version]                 NVARCHAR (50)  CONSTRAINT [DF_Product_Definitions_Version] DEFAULT ('1') NOT NULL,
    CONSTRAINT [PK_Product_Definitions] PRIMARY KEY CLUSTERED ([Product_Definition_Id] ASC),
    CONSTRAINT [FK_Product_Definitions_Characteristics] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [FK_Product_Definitions_Products] FOREIGN KEY ([Production_Rule_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Product_Definitions_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [IX_Product_Definitions] UNIQUE NONCLUSTERED ([Product_Definition_Name] ASC, [Version] DESC, [Production_Rule_Id] ASC)
);


GO
CREATE TRIGGER [dbo].[Product_Definitions_History_Del]
 ON  [dbo].[Product_Definitions]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Definition_History
 	  	   (Char_Id,Comment_Id,Effective_Date,Entry_On,Expiration_Date,IsReleased,Product_Definition_Desc,Product_Definition_Id,Product_Definition_Name,Production_Rule_Id,User_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Id,a.Comment_Id,a.Effective_Date,a.Entry_On,a.Expiration_Date,a.IsReleased,a.Product_Definition_Desc,a.Product_Definition_Id,a.Product_Definition_Name,a.Production_Rule_Id,a.User_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Definitions_History_Ins]
 ON  [dbo].[Product_Definitions]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Definition_History
 	  	   (Char_Id,Comment_Id,Effective_Date,Entry_On,Expiration_Date,IsReleased,Product_Definition_Desc,Product_Definition_Id,Product_Definition_Name,Production_Rule_Id,User_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Id,a.Comment_Id,a.Effective_Date,a.Entry_On,a.Expiration_Date,a.IsReleased,a.Product_Definition_Desc,a.Product_Definition_Id,a.Product_Definition_Name,a.Production_Rule_Id,a.User_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Definitions_History_Upd]
 ON  [dbo].[Product_Definitions]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Definition_History
 	  	   (Char_Id,Comment_Id,Effective_Date,Entry_On,Expiration_Date,IsReleased,Product_Definition_Desc,Product_Definition_Id,Product_Definition_Name,Production_Rule_Id,User_Id,Version,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Id,a.Comment_Id,a.Effective_Date,a.Entry_On,a.Expiration_Date,a.IsReleased,a.Product_Definition_Desc,a.Product_Definition_Id,a.Product_Definition_Name,a.Production_Rule_Id,a.User_Id,a.Version,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
