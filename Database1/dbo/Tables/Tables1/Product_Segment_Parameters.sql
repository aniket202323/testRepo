CREATE TABLE [dbo].[Product_Segment_Parameters] (
    [Product_Segment_Parameter_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Entry_On]                     DATETIME      NOT NULL,
    [L_Entry]                      NVARCHAR (50) NULL,
    [L_Reject]                     NVARCHAR (50) NULL,
    [L_User]                       NVARCHAR (50) NULL,
    [L_Warning]                    NVARCHAR (50) NULL,
    [Overridden]                   BIT           CONSTRAINT [DF_Product_Segment_Parameters_Overridden] DEFAULT ((0)) NOT NULL,
    [Parameter_Id]                 INT           NOT NULL,
    [Precision]                    TINYINT       NULL,
    [Product_Segment_Id]           INT           NOT NULL,
    [Sequence]                     INT           CONSTRAINT [DF_Product_Segment_Parameters_Order] DEFAULT ((1)) NOT NULL,
    [Spec_Id]                      INT           NULL,
    [U_Entry]                      NVARCHAR (50) NULL,
    [U_Reject]                     NVARCHAR (50) NULL,
    [U_User]                       NVARCHAR (50) NULL,
    [U_Warning]                    NVARCHAR (50) NULL,
    [User_id]                      INT           NOT NULL,
    [Value]                        NVARCHAR (50) NULL,
    CONSTRAINT [PK_Product_Segment_Parameters] PRIMARY KEY CLUSTERED ([Product_Segment_Parameter_Id] ASC),
    CONSTRAINT [FK_Product_Segment_Parameters_Product_Segments] FOREIGN KEY ([Product_Segment_Id]) REFERENCES [dbo].[Product_Segments] ([Product_Segment_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Product_Segment_Parameters_Segment_Parameters] FOREIGN KEY ([Parameter_Id]) REFERENCES [dbo].[Segment_Parameters] ([Parameter_Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Product_Segment_Parameters_Specifications] FOREIGN KEY ([Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [FK_Product_Segment_Parameters_Users] FOREIGN KEY ([User_id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[Product_Segment_Parameters_History_Upd]
 ON  [dbo].[Product_Segment_Parameters]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Segment_Parameter_History
 	  	   (Entry_On,L_Entry,L_Reject,L_User,L_Warning,Overridden,Parameter_Id,Precision,Product_Segment_Id,Product_Segment_Parameter_Id,Sequence,Spec_Id,U_Entry,U_Reject,U_User,U_Warning,User_id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Overridden,a.Parameter_Id,a.Precision,a.Product_Segment_Id,a.Product_Segment_Parameter_Id,a.Sequence,a.Spec_Id,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Segment_Parameters_History_Ins]
 ON  [dbo].[Product_Segment_Parameters]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Segment_Parameter_History
 	  	   (Entry_On,L_Entry,L_Reject,L_User,L_Warning,Overridden,Parameter_Id,Precision,Product_Segment_Id,Product_Segment_Parameter_Id,Sequence,Spec_Id,U_Entry,U_Reject,U_User,U_Warning,User_id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Overridden,a.Parameter_Id,a.Precision,a.Product_Segment_Id,a.Product_Segment_Parameter_Id,a.Sequence,a.Spec_Id,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Segment_Parameters_History_Del]
 ON  [dbo].[Product_Segment_Parameters]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Segment_Parameter_History
 	  	   (Entry_On,L_Entry,L_Reject,L_User,L_Warning,Overridden,Parameter_Id,Precision,Product_Segment_Id,Product_Segment_Parameter_Id,Sequence,Spec_Id,U_Entry,U_Reject,U_User,U_Warning,User_id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Overridden,a.Parameter_Id,a.Precision,a.Product_Segment_Id,a.Product_Segment_Parameter_Id,a.Sequence,a.Spec_Id,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
