CREATE TABLE [dbo].[Process_Segment_Parameters] (
    [PS_Parameter_Id]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]           DATETIME      NOT NULL,
    [L_Entry]            NVARCHAR (50) NULL,
    [L_Reject]           NVARCHAR (50) NULL,
    [L_User]             NVARCHAR (50) NULL,
    [L_Warning]          NVARCHAR (50) NULL,
    [Parameter_Id]       INT           NOT NULL,
    [Process_Segment_Id] INT           NOT NULL,
    [Sequence]           INT           NOT NULL,
    [U_Entry]            NVARCHAR (50) NULL,
    [U_Reject]           NVARCHAR (50) NULL,
    [U_User]             NVARCHAR (50) NULL,
    [U_Warning]          NVARCHAR (50) NULL,
    [User_Id]            INT           NOT NULL,
    [Value]              NVARCHAR (50) NULL,
    CONSTRAINT [PK_Process_Segment_Parameters] PRIMARY KEY CLUSTERED ([PS_Parameter_Id] ASC),
    CONSTRAINT [FK_Process_Segment_Parameters_Process_Segments] FOREIGN KEY ([Process_Segment_Id]) REFERENCES [dbo].[Process_Segments] ([Process_Segment_Id]),
    CONSTRAINT [FK_Process_Segment_Parameters_Segment_Parameters] FOREIGN KEY ([Parameter_Id]) REFERENCES [dbo].[Segment_Parameters] ([Parameter_Id]),
    CONSTRAINT [FK_Process_Segment_Parameters_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Process_Segment_Parameters_History_Ins]
 ON  [dbo].[Process_Segment_Parameters]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Process_Segment_Parameter_History
 	  	   (Entry_On,L_Entry,L_Reject,L_User,L_Warning,Parameter_Id,Process_Segment_Id,PS_Parameter_Id,Sequence,U_Entry,U_Reject,U_User,U_Warning,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Parameter_Id,a.Process_Segment_Id,a.PS_Parameter_Id,a.Sequence,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Parameters_History_Del]
 ON  [dbo].[Process_Segment_Parameters]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Process_Segment_Parameter_History
 	  	   (Entry_On,L_Entry,L_Reject,L_User,L_Warning,Parameter_Id,Process_Segment_Id,PS_Parameter_Id,Sequence,U_Entry,U_Reject,U_User,U_Warning,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Parameter_Id,a.Process_Segment_Id,a.PS_Parameter_Id,a.Sequence,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Process_Segment_Parameters_History_Upd]
 ON  [dbo].[Process_Segment_Parameters]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Process_Segment_Parameter_History
 	  	   (Entry_On,L_Entry,L_Reject,L_User,L_Warning,Parameter_Id,Process_Segment_Id,PS_Parameter_Id,Sequence,U_Entry,U_Reject,U_User,U_Warning,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Parameter_Id,a.Process_Segment_Id,a.PS_Parameter_Id,a.Sequence,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
