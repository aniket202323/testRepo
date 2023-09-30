CREATE TABLE [dbo].[Process_Segment_Dependencies] (
    [PS_Dependency_Id]   INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dependency_Id]      INT      CONSTRAINT [DF_Process_Segment_Dependencies_Dependency_Id] DEFAULT ((1)) NOT NULL,
    [Designated_PS_Id]   INT      NOT NULL,
    [Entry_On]           DATETIME NOT NULL,
    [Process_Segment_Id] INT      NOT NULL,
    [User_Id]            INT      NOT NULL,
    CONSTRAINT [PK_Process_Segment_Dependencies] PRIMARY KEY CLUSTERED ([PS_Dependency_Id] ASC),
    CONSTRAINT [FK_Process_Segment_Dependencies_Dependencies] FOREIGN KEY ([Dependency_Id]) REFERENCES [dbo].[Dependencies] ([Dependency_Id]),
    CONSTRAINT [FK_Process_Segment_Dependencies_Process_Segments1] FOREIGN KEY ([Process_Segment_Id]) REFERENCES [dbo].[Process_Segments] ([Process_Segment_Id]),
    CONSTRAINT [FK_Process_Segment_Dependencies_Process_Segments2] FOREIGN KEY ([Designated_PS_Id]) REFERENCES [dbo].[Process_Segments] ([Process_Segment_Id]),
    CONSTRAINT [FK_Process_Segment_Dependencies_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Process_Segment_Dependencies_History_Upd]
 ON  [dbo].[Process_Segment_Dependencies]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Process_Segment_Dependency_History
 	  	   (Dependency_Id,Designated_PS_Id,Entry_On,Process_Segment_Id,PS_Dependency_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Id,a.Designated_PS_Id,a.Entry_On,a.Process_Segment_Id,a.PS_Dependency_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Dependencies_History_Del]
 ON  [dbo].[Process_Segment_Dependencies]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Process_Segment_Dependency_History
 	  	   (Dependency_Id,Designated_PS_Id,Entry_On,Process_Segment_Id,PS_Dependency_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Id,a.Designated_PS_Id,a.Entry_On,a.Process_Segment_Id,a.PS_Dependency_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Dependencies_History_Ins]
 ON  [dbo].[Process_Segment_Dependencies]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Process_Segment_Dependency_History
 	  	   (Dependency_Id,Designated_PS_Id,Entry_On,Process_Segment_Id,PS_Dependency_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Id,a.Designated_PS_Id,a.Entry_On,a.Process_Segment_Id,a.PS_Dependency_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
