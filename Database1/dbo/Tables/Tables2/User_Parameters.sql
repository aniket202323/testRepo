CREATE TABLE [dbo].[User_Parameters] (
    [HostName]      VARCHAR (50)   NOT NULL,
    [Parm_Id]       INT            NOT NULL,
    [Parm_Required] BIT            CONSTRAINT [User_Parameters_DF_Required] DEFAULT ((0)) NOT NULL,
    [User_Id]       INT            NOT NULL,
    [Value]         VARCHAR (5000) NOT NULL,
    CONSTRAINT [PK_User_Parameters] PRIMARY KEY NONCLUSTERED ([User_Id] ASC, [Parm_Id] ASC, [HostName] ASC),
    CONSTRAINT [UserParams_FK_ParamId] FOREIGN KEY ([Parm_Id]) REFERENCES [dbo].[Parameters] ([Parm_Id]),
    CONSTRAINT [UserParams_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE TRIGGER [dbo].[User_Parameters_History_Del]
 ON  [dbo].[User_Parameters]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 434
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into User_Parameter_History
 	  	   (HostName,Parm_Id,Parm_Required,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.HostName,a.Parm_Id,a.Parm_Required,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[User_Parameters_History_Upd]
 ON  [dbo].[User_Parameters]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 434
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into User_Parameter_History
 	  	   (HostName,Parm_Id,Parm_Required,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.HostName,a.Parm_Id,a.Parm_Required,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[User_Parameters_History_Ins]
 ON  [dbo].[User_Parameters]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 434
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into User_Parameter_History
 	  	   (HostName,Parm_Id,Parm_Required,User_Id,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.HostName,a.Parm_Id,a.Parm_Required,a.User_Id,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
