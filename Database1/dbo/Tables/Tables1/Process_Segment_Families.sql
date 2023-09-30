CREATE TABLE [dbo].[Process_Segment_Families] (
    [Process_Segment_Family_Id]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]                    DATETIME       NOT NULL,
    [Parent_PSF_Id]               INT            NULL,
    [Process_Segment_Family_Desc] NVARCHAR (300) NOT NULL,
    [User_Id]                     INT            NOT NULL,
    CONSTRAINT [PK_Process_Segment_Families] PRIMARY KEY CLUSTERED ([Process_Segment_Family_Id] ASC),
    CONSTRAINT [FK_Process_Segment_Families_Process_Segment_Families] FOREIGN KEY ([Parent_PSF_Id]) REFERENCES [dbo].[Process_Segment_Families] ([Process_Segment_Family_Id]),
    CONSTRAINT [FK_Process_Segment_Families_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [IX_Process_Segment_Families] UNIQUE NONCLUSTERED ([Process_Segment_Family_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Process_Segment_Families_History_Ins]
 ON  [dbo].[Process_Segment_Families]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Process_Segment_Family_History
 	  	   (Entry_On,Parent_PSF_Id,Process_Segment_Family_Desc,Process_Segment_Family_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Parent_PSF_Id,a.Process_Segment_Family_Desc,a.Process_Segment_Family_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Families_History_Upd]
 ON  [dbo].[Process_Segment_Families]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Process_Segment_Family_History
 	  	   (Entry_On,Parent_PSF_Id,Process_Segment_Family_Desc,Process_Segment_Family_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Parent_PSF_Id,a.Process_Segment_Family_Desc,a.Process_Segment_Family_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Families_History_Del]
 ON  [dbo].[Process_Segment_Families]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Process_Segment_Family_History
 	  	   (Entry_On,Parent_PSF_Id,Process_Segment_Family_Desc,Process_Segment_Family_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.Parent_PSF_Id,a.Process_Segment_Family_Desc,a.Process_Segment_Family_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
