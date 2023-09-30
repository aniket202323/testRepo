CREATE TABLE [dbo].[Segment_Parameters] (
    [Parameter_Id]    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data_Type_Id]    INT            NOT NULL,
    [Eng_Unit_Id]     INT            NULL,
    [Entry_On]        DATETIME       NOT NULL,
    [L_Entry]         NVARCHAR (50)  NULL,
    [L_Reject]        NVARCHAR (50)  NULL,
    [L_User]          NVARCHAR (50)  NULL,
    [L_Warning]       NVARCHAR (50)  NULL,
    [Mask]            NVARCHAR (50)  NULL,
    [Parameter_Code]  NVARCHAR (50)  NOT NULL,
    [Parameter_Desc]  NVARCHAR (300) CONSTRAINT [DF_Segment_Parameters_Parameter_Desc] DEFAULT ('') NOT NULL,
    [Parameter_Name]  NVARCHAR (50)  CONSTRAINT [DF_Segment_Parameters_Parameter_Name] DEFAULT ('') NOT NULL,
    [Segment_Default] NVARCHAR (50)  NULL,
    [U_Entry]         NVARCHAR (50)  NULL,
    [U_Reject]        NVARCHAR (50)  NULL,
    [U_User]          NVARCHAR (50)  NULL,
    [U_Warning]       NVARCHAR (50)  NULL,
    [User_Id]         INT            NOT NULL,
    CONSTRAINT [PK_Segment_Parameters] PRIMARY KEY CLUSTERED ([Parameter_Id] ASC),
    CONSTRAINT [FK_Segment_Parameters_Data_Type] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id]),
    CONSTRAINT [FK_Segment_Parameters_Engineering_Unit] FOREIGN KEY ([Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [FK_Segment_Parameters_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [IX_Segment_Parameters] UNIQUE NONCLUSTERED ([Parameter_Code] ASC, [Parameter_Name] ASC)
);


GO
CREATE TRIGGER [dbo].[Segment_Parameters_History_Del]
 ON  [dbo].[Segment_Parameters]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Segment_Parameter_History
 	  	   (Data_Type_Id,Eng_Unit_Id,Entry_On,L_Entry,L_Reject,L_User,L_Warning,Mask,Parameter_Code,Parameter_Desc,Parameter_Id,Parameter_Name,Segment_Default,U_Entry,U_Reject,U_User,U_Warning,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Data_Type_Id,a.Eng_Unit_Id,a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Mask,a.Parameter_Code,a.Parameter_Desc,a.Parameter_Id,a.Parameter_Name,a.Segment_Default,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Segment_Parameters_History_Upd]
 ON  [dbo].[Segment_Parameters]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Segment_Parameter_History
 	  	   (Data_Type_Id,Eng_Unit_Id,Entry_On,L_Entry,L_Reject,L_User,L_Warning,Mask,Parameter_Code,Parameter_Desc,Parameter_Id,Parameter_Name,Segment_Default,U_Entry,U_Reject,U_User,U_Warning,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Data_Type_Id,a.Eng_Unit_Id,a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Mask,a.Parameter_Code,a.Parameter_Desc,a.Parameter_Id,a.Parameter_Name,a.Segment_Default,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Segment_Parameters_History_Ins]
 ON  [dbo].[Segment_Parameters]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Segment_Parameter_History
 	  	   (Data_Type_Id,Eng_Unit_Id,Entry_On,L_Entry,L_Reject,L_User,L_Warning,Mask,Parameter_Code,Parameter_Desc,Parameter_Id,Parameter_Name,Segment_Default,U_Entry,U_Reject,U_User,U_Warning,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Data_Type_Id,a.Eng_Unit_Id,a.Entry_On,a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Mask,a.Parameter_Code,a.Parameter_Desc,a.Parameter_Id,a.Parameter_Name,a.Segment_Default,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
