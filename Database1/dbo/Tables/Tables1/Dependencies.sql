CREATE TABLE [dbo].[Dependencies] (
    [Dependency_Id]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dependency_Desc] NVARCHAR (300) NULL,
    [Dependency_Name] NVARCHAR (50)  NOT NULL,
    [Entry_On]        DATETIME       NULL,
    [User_Id]         INT            CONSTRAINT [DF_Dependencies_User_Id] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Dependencies] PRIMARY KEY CLUSTERED ([Dependency_Id] ASC),
    CONSTRAINT [FK_Dependencies_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [IX_Dependencies] UNIQUE NONCLUSTERED ([Dependency_Name] ASC)
);


GO
CREATE TRIGGER [dbo].[Dependencies_History_Upd]
 ON  [dbo].[Dependencies]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Dependency_History
 	  	   (Dependency_Desc,Dependency_Id,Dependency_Name,Entry_On,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Desc,a.Dependency_Id,a.Dependency_Name,a.Entry_On,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Dependencies_History_Ins]
 ON  [dbo].[Dependencies]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Dependency_History
 	  	   (Dependency_Desc,Dependency_Id,Dependency_Name,Entry_On,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Desc,a.Dependency_Id,a.Dependency_Name,a.Entry_On,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Dependencies_History_Del]
 ON  [dbo].[Dependencies]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 454
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Dependency_History
 	  	   (Dependency_Desc,Dependency_Id,Dependency_Name,Entry_On,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Dependency_Desc,a.Dependency_Id,a.Dependency_Name,a.Entry_On,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
