CREATE TABLE [dbo].[Process_Segment_Components] (
    [Implementation_Id]        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Code]                     NVARCHAR (50) NULL,
    [Comment_Id]               INT           NULL,
    [Entry_On]                 DATETIME      NOT NULL,
    [Parent_Implementation_Id] INT           NULL,
    [Segment_Reference_Id]     INT           NOT NULL,
    [Sequence]                 INT           CONSTRAINT [DF_Process_Segment_Components_Order] DEFAULT ((1)) NOT NULL,
    [User_Id]                  INT           NOT NULL,
    CONSTRAINT [PK_Process_Segment_Components] PRIMARY KEY CLUSTERED ([Implementation_Id] ASC),
    CONSTRAINT [FK_Process_Segment_Components_Process_Segment_Components] FOREIGN KEY ([Parent_Implementation_Id]) REFERENCES [dbo].[Process_Segment_Components] ([Implementation_Id]),
    CONSTRAINT [FK_Process_Segment_Components_Process_Segments1] FOREIGN KEY ([Segment_Reference_Id]) REFERENCES [dbo].[Process_Segments] ([Process_Segment_Id]),
    CONSTRAINT [FK_Process_Segment_Components_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Process_Segment_Components_History_Ins]
 ON  [dbo].[Process_Segment_Components]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Process_Segment_Component_History
 	  	   (Code,Comment_Id,Entry_On,Implementation_Id,Parent_Implementation_Id,Segment_Reference_Id,Sequence,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Code,a.Comment_Id,a.Entry_On,a.Implementation_Id,a.Parent_Implementation_Id,a.Segment_Reference_Id,a.Sequence,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Components_History_Upd]
 ON  [dbo].[Process_Segment_Components]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Process_Segment_Component_History
 	  	   (Code,Comment_Id,Entry_On,Implementation_Id,Parent_Implementation_Id,Segment_Reference_Id,Sequence,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Code,a.Comment_Id,a.Entry_On,a.Implementation_Id,a.Parent_Implementation_Id,a.Segment_Reference_Id,a.Sequence,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Components_History_Del]
 ON  [dbo].[Process_Segment_Components]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Process_Segment_Component_History
 	  	   (Code,Comment_Id,Entry_On,Implementation_Id,Parent_Implementation_Id,Segment_Reference_Id,Sequence,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Code,a.Comment_Id,a.Entry_On,a.Implementation_Id,a.Parent_Implementation_Id,a.Segment_Reference_Id,a.Sequence,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
