CREATE TABLE [dbo].[Process_Segments] (
    [Process_Segment_Id]        INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]                  DATETIME       NOT NULL,
    [Process_Segment_Desc]      NVARCHAR (300) NULL,
    [Process_Segment_Family_Id] INT            NOT NULL,
    [Process_Segment_Name]      NVARCHAR (50)  NOT NULL,
    [User_Id]                   INT            NOT NULL,
    CONSTRAINT [PK_Process_Segments_1] PRIMARY KEY CLUSTERED ([Process_Segment_Id] ASC),
    CONSTRAINT [FK_Process_Segments_Process_Segment_Families] FOREIGN KEY ([Process_Segment_Family_Id]) REFERENCES [dbo].[Process_Segment_Families] ([Process_Segment_Family_Id]),
    CONSTRAINT [FK_Process_Segments_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [IX_Process_Segments] UNIQUE NONCLUSTERED ([Process_Segment_Family_Id] ASC, [Process_Segment_Name] ASC)
);


GO
CREATE TRIGGER [dbo].[Process_Segments_History_Upd]
 ON  [dbo].[Process_Segments]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Process_Segment_History
 	  	   (Entry_On,Process_Segment_Desc,Process_Segment_Family_Id,Process_Segment_Id,Process_Segment_Name,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Process_Segment_Desc,a.Process_Segment_Family_Id,a.Process_Segment_Id,a.Process_Segment_Name,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segments_History_Ins]
 ON  [dbo].[Process_Segments]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Process_Segment_History
 	  	   (Entry_On,Process_Segment_Desc,Process_Segment_Family_Id,Process_Segment_Id,Process_Segment_Name,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Process_Segment_Desc,a.Process_Segment_Family_Id,a.Process_Segment_Id,a.Process_Segment_Name,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segments_History_Del]
 ON  [dbo].[Process_Segments]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Process_Segment_History
 	  	   (Entry_On,Process_Segment_Desc,Process_Segment_Family_Id,Process_Segment_Id,Process_Segment_Name,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Process_Segment_Desc,a.Process_Segment_Family_Id,a.Process_Segment_Id,a.Process_Segment_Name,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
