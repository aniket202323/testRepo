CREATE TABLE [dbo].[Process_Segment_Equipment] (
    [PS_Equipment_Id]    INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]           DATETIME NOT NULL,
    [Key_Id]             INT      NOT NULL,
    [Process_Segment_Id] INT      NOT NULL,
    [Table_Id]           INT      NOT NULL,
    [User_id]            INT      NOT NULL,
    CONSTRAINT [PK_Process_Segment_Equipment] PRIMARY KEY CLUSTERED ([PS_Equipment_Id] ASC),
    CONSTRAINT [FK_Process_Segment_Equipment_Process_Segments] FOREIGN KEY ([Process_Segment_Id]) REFERENCES [dbo].[Process_Segments] ([Process_Segment_Id]),
    CONSTRAINT [FK_Process_Segment_Equipment_Users] FOREIGN KEY ([User_id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Process_Segment_Equipment_History_Upd]
 ON  [dbo].[Process_Segment_Equipment]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Process_Segment_Equipment_History
 	  	   (Entry_On,Key_Id,Process_Segment_Id,PS_Equipment_Id,Table_Id,User_id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Key_Id,a.Process_Segment_Id,a.PS_Equipment_Id,a.Table_Id,a.User_id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Equipment_History_Del]
 ON  [dbo].[Process_Segment_Equipment]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Process_Segment_Equipment_History
 	  	   (Entry_On,Key_Id,Process_Segment_Id,PS_Equipment_Id,Table_Id,User_id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Key_Id,a.Process_Segment_Id,a.PS_Equipment_Id,a.Table_Id,a.User_id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Equipment_History_Ins]
 ON  [dbo].[Process_Segment_Equipment]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Process_Segment_Equipment_History
 	  	   (Entry_On,Key_Id,Process_Segment_Id,PS_Equipment_Id,Table_Id,User_id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Key_Id,a.Process_Segment_Id,a.PS_Equipment_Id,a.Table_Id,a.User_id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
