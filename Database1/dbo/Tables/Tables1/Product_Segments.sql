CREATE TABLE [dbo].[Product_Segments] (
    [Product_Segment_Id]    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Code]                  NVARCHAR (50)  NULL,
    [Entry_On]              DATETIME       NOT NULL,
    [Parent_PS_Id]          INT            NULL,
    [Process_Segment_Id]    INT            NOT NULL,
    [Product_Definition_Id] INT            NOT NULL,
    [Product_Segment_Desc]  NVARCHAR (300) NULL,
    [Product_Segment_Name]  NVARCHAR (50)  NOT NULL,
    [Sequence]              INT            CONSTRAINT [DF_Product_Segments_Order] DEFAULT ((1)) NOT NULL,
    [User_Id]               INT            NOT NULL,
    CONSTRAINT [PK_Product_Segments] PRIMARY KEY CLUSTERED ([Product_Segment_Id] ASC),
    CONSTRAINT [FK_Product_Segments_Process_Segments] FOREIGN KEY ([Process_Segment_Id]) REFERENCES [dbo].[Process_Segments] ([Process_Segment_Id]),
    CONSTRAINT [FK_Product_Segments_Product_Definitions] FOREIGN KEY ([Product_Definition_Id]) REFERENCES [dbo].[Product_Definitions] ([Product_Definition_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Product_Segments_Product_Segments] FOREIGN KEY ([Parent_PS_Id]) REFERENCES [dbo].[Product_Segments] ([Product_Segment_Id]),
    CONSTRAINT [FK_Product_Segments_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Segments_History_Upd]
 ON  [dbo].[Product_Segments]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Segment_History
 	  	   (Code,Entry_On,Parent_PS_Id,Process_Segment_Id,Product_Definition_Id,Product_Segment_Desc,Product_Segment_Id,Product_Segment_Name,Sequence,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Code,a.Entry_On,a.Parent_PS_Id,a.Process_Segment_Id,a.Product_Definition_Id,a.Product_Segment_Desc,a.Product_Segment_Id,a.Product_Segment_Name,a.Sequence,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Segments_History_Del]
 ON  [dbo].[Product_Segments]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Segment_History
 	  	   (Code,Entry_On,Parent_PS_Id,Process_Segment_Id,Product_Definition_Id,Product_Segment_Desc,Product_Segment_Id,Product_Segment_Name,Sequence,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Code,a.Entry_On,a.Parent_PS_Id,a.Process_Segment_Id,a.Product_Definition_Id,a.Product_Segment_Desc,a.Product_Segment_Id,a.Product_Segment_Name,a.Sequence,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Segments_History_Ins]
 ON  [dbo].[Product_Segments]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Segment_History
 	  	   (Code,Entry_On,Parent_PS_Id,Process_Segment_Id,Product_Definition_Id,Product_Segment_Desc,Product_Segment_Id,Product_Segment_Name,Sequence,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Code,a.Entry_On,a.Parent_PS_Id,a.Process_Segment_Id,a.Product_Definition_Id,a.Product_Segment_Desc,a.Product_Segment_Id,a.Product_Segment_Name,a.Sequence,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
