CREATE TABLE [dbo].[Users_Base] (
    [User_Id]             INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Active]              BIT                       CONSTRAINT [User_DF_Active] DEFAULT ((1)) NOT NULL,
    [Is_Role]             BIT                       CONSTRAINT [User_DF_IsRole] DEFAULT ((0)) NOT NULL,
    [Mixed_Mode_Login]    BIT                       CONSTRAINT [User_DF_MixedMode] DEFAULT ((1)) NOT NULL,
    [Password]            [dbo].[Varchar_Username]  NULL,
    [Role_Based_Security] BIT                       CONSTRAINT [User_DF_RoleBased] DEFAULT ((0)) NOT NULL,
    [SSOUserId]           VARCHAR (50)              NULL,
    [System]              TINYINT                   CONSTRAINT [User_DF_System] DEFAULT ((0)) NULL,
    [User_Desc]           [dbo].[Varchar_Long_Desc] NULL,
    [Username]            [dbo].[Varchar_Username]  NOT NULL,
    [UseSSO]              BIT                       NULL,
    [View_Id]             INT                       NULL,
    [WindowsUserInfo]     VARCHAR (200)             NULL,
    CONSTRAINT [Users_PK_UserId] PRIMARY KEY CLUSTERED ([User_Id] ASC),
    CONSTRAINT [Users_By_Username] UNIQUE NONCLUSTERED ([Username] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Username]
    ON [dbo].[Users_Base]([Username] ASC);


GO
CREATE NONCLUSTERED INDEX [Ix_Users_base_Username]
    ON [dbo].[Users_Base]([Username] ASC);


GO
CREATE TRIGGER [dbo].[Users_History_Ins]
 ON  [dbo].[Users_Base]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 437
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into User_History
 	  	   (Active,Is_Role,Mixed_Mode_Login,Password,Role_Based_Security,SSOUserId,System,User_Desc,User_Id,Username,UseSSO,View_Id,WindowsUserInfo,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Active,a.Is_Role,a.Mixed_Mode_Login,a.Password,a.Role_Based_Security,a.SSOUserId,a.System,a.User_Desc,a.User_Id,a.Username,a.UseSSO,a.View_Id,a.WindowsUserInfo,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[UsersUpdate]
 ON  [dbo].[Users_Base]
  FOR Update
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
Declare 
  @DeletedPW VarChar(100),
  @AddedPW VarChar(100),
  @AddedUserInfo VarChar(255),
  @UserId Int
DECLARE @Start Int,@End Int
DECLARE @UpdatedTable Table(id Int identity(1,1),User_Id Int,Password VarChar(100),WindowsUserInfo VarChar(255))
INSERT INTO @UpdatedTable(User_Id,Password,WindowsUserInfo)
 	  SELECT User_Id,Password,WindowsUserInfo FROM INSERTED
SELECT @Start = MIn(Id),@End = Max(id) From @UpdatedTable
WHILE @Start < = @End
BEGIN
 	 SELECT @UserId = NULL,@AddedPW = NULL,@AddedUserInfo = NULL 
 	 SELECT  @UserId = User_Id,@AddedPW = Password,@AddedUserInfo = WindowsUserInfo 
 	  	 FROM @UpdatedTable WHERE id = @Start
 	 IF @AddedUserInfo = '' SELECT @AddedUserInfo = Null
 	 SELECT @DeletedPW = Password
 	  	 From DELETED WHERE (User_Id = @UserId)
 	 IF ISDATE(@DeletedPW) = 1 and ISDATE(@AddedPW) = 0 and (@AddedUserInfo is Null)
 	 BEGIN 
 	   IF EXISTS(SELECT 1 FROM Users_base WHERE User_Id = @UserId AND System = 0 AND Active = 1 and Is_Role = 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
 	  	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId)
 	  	  	  	 VALUES(@UserId,-36)
 	 END
   	 SET @Start = @Start + 1
END
END

GO
CREATE TRIGGER [dbo].[Users_History_Del]
 ON  [dbo].[Users_Base]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 437
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into User_History
 	  	   (Active,Is_Role,Mixed_Mode_Login,Password,Role_Based_Security,SSOUserId,System,User_Desc,User_Id,Username,UseSSO,View_Id,WindowsUserInfo,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Active,a.Is_Role,a.Mixed_Mode_Login,a.Password,a.Role_Based_Security,a.SSOUserId,a.System,a.User_Desc,a.User_Id,a.Username,a.UseSSO,a.View_Id,a.WindowsUserInfo,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Users_History_Upd]
 ON  [dbo].[Users_Base]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 437
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into User_History
 	  	   (Active,Is_Role,Mixed_Mode_Login,Password,Role_Based_Security,SSOUserId,System,User_Desc,User_Id,Username,UseSSO,View_Id,WindowsUserInfo,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Active,a.Is_Role,a.Mixed_Mode_Login,a.Password,a.Role_Based_Security,a.SSOUserId,a.System,a.User_Desc,a.User_Id,a.Username,a.UseSSO,a.View_Id,a.WindowsUserInfo,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Users_TableFieldValue_Del]
 ON  [dbo].[Users_Base]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.User_Id
 WHERE tfv.TableId = 36
