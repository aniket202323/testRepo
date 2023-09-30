CREATE TABLE [dbo].[Production_Starts] (
    [Start_Id]         INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]       INT      NULL,
    [Confirmed]        BIT      CONSTRAINT [ProdStarts_DF_Confirmed] DEFAULT ((0)) NOT NULL,
    [End_Time]         DATETIME NULL,
    [Event_Subtype_Id] INT      NULL,
    [Prod_Id]          INT      NOT NULL,
    [PU_Id]            INT      NOT NULL,
    [Second_User_Id]   INT      NULL,
    [Signature_Id]     INT      NULL,
    [Start_Time]       DATETIME NOT NULL,
    [User_Id]          INT      NULL,
    CONSTRAINT [ProdStarts_PK_StartId] PRIMARY KEY NONCLUSTERED ([Start_Id] ASC),
    CONSTRAINT [ProdStarts_CC_STimeETime] CHECK ([Start_Time]<[End_Time] OR [End_Time] IS NULL),
    CONSTRAINT [ProdStarts_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [ProdStarts_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Production_Starts_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [ProductionStartsSecondUser_FK_Users] FOREIGN KEY ([Second_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [ProductionStartsUserId_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Production_Starts_By_PU_Start] UNIQUE CLUSTERED ([PU_Id] ASC, [Start_Time] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PS_Start_By_Product]
    ON [dbo].[Production_Starts]([PU_Id] ASC, [Prod_Id] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [Ix_productionstarts_PUIDStarttime_Endtime]
    ON [dbo].[Production_Starts]([PU_Id] ASC, [Start_Time] ASC, [End_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PRODUCTIONSTARTS_PUID_STARTTIME_ENDTIME_PRODID]
    ON [dbo].[Production_Starts]([PU_Id] ASC, [Start_Time] ASC, [End_Time] ASC, [Prod_Id] ASC);


GO
CREATE TRIGGER dbo.Production_Starts_Del
  ON dbo.Production_Starts
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@StartId int,
  @@ProdId int,
  @@PUId int,
  @@Start_Time datetime,
 	 @Comment_Id int
Declare Production_Starts_Del_Cursor INSENSITIVE CURSOR
  For (Select Start_Id,Prod_Id,PU_Id,Start_Time, Comment_Id From DELETED Where Prod_Id > 1)
  For Read Only
  Open Production_Starts_Del_Cursor  
Fetch_Loop:
  Fetch Next From Production_Starts_Del_Cursor Into @@StartId,@@ProdId,@@PUId,@@Start_Time,@Comment_Id
  If (@@Fetch_Status = 0)
    Begin
      If @Comment_Id is NOT NULL 
        BEGIN
          Delete From Comments Where TopOfChain_Id = @Comment_Id 
          Delete From Comments Where Comment_Id = @Comment_Id   
        END
      Execute spServer_CmnRemoveScheduledTask @@StartId,2
      Goto Fetch_Loop
    End
Close Production_Starts_Del_Cursor
Deallocate Production_Starts_Del_Cursor

GO
CREATE TRIGGER [dbo].[Production_Starts_History_Ins]
 ON  [dbo].[Production_Starts]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 416
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Production_Starts_History
 	  	   (Comment_Id,Confirmed,End_Time,Event_Subtype_Id,Prod_Id,PU_Id,Second_User_Id,Signature_Id,Start_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Confirmed,a.End_Time,a.Event_Subtype_Id,a.Prod_Id,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Start_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Production_Starts_Upd
  ON dbo.Production_Starts
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@StartId int,
  @@ProdId int,
  @@PUId int,
  @@Start_Time datetime,
  @@End_Time datetime,
  @Old_EndTime datetime
Declare Production_Starts_Upd_Cursor INSENSITIVE CURSOR
  For (Select Start_Id,Prod_Id,PU_Id,Start_Time,End_Time From INSERTED)
  For Read Only
  Open Production_Starts_Upd_Cursor  
Fetch_Loop:
  Fetch Next From Production_Starts_Upd_Cursor Into @@StartId,@@ProdId,@@PUId,@@Start_Time,@@End_Time
  If (@@Fetch_Status = 0)
    Begin
      If (@@ProdId > 1)
        Begin
          SELECT @Old_EndTime = NULL
          SELECT @Old_EndTime = End_Time FROM DELETED WHERE (Start_Id = @@StartId)
          if (@Old_EndTime = @@End_Time)
            SELECT @Old_EndTime = NULL
       	   Execute spServer_CmnAddScheduledTask @@StartId,2,@@PUId,@@Start_Time,null,null,null,null,@Old_EndTime
        End
      Goto Fetch_Loop
    End
Close Production_Starts_Upd_Cursor
Deallocate Production_Starts_Upd_Cursor

GO
CREATE TRIGGER [dbo].[Production_Starts_History_Del]
 ON  [dbo].[Production_Starts]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 416
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Production_Starts_History
 	  	   (Comment_Id,Confirmed,End_Time,Event_Subtype_Id,Prod_Id,PU_Id,Second_User_Id,Signature_Id,Start_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Confirmed,a.End_Time,a.Event_Subtype_Id,a.Prod_Id,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Start_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Production_Starts_Ins
  ON dbo.Production_Starts
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@StartId int,
  @@ProdId int,
  @@PUId int,
  @@Start_Time datetime
Declare Production_Starts_Ins_Cursor INSENSITIVE CURSOR
  For (Select Start_Id,Prod_Id,PU_Id,Start_Time From INSERTED)
  For Read Only
  Open Production_Starts_Ins_Cursor  
Fetch_Loop:
  Fetch Next From Production_Starts_Ins_Cursor Into @@StartId,@@ProdId,@@PUId,@@Start_Time
  If (@@Fetch_Status = 0)
    Begin
      If (@@ProdId > 1)
        Begin 
       	   Execute spServer_CmnAddScheduledTask @@StartId,2,@@PUId,@@Start_Time
        End
      Goto Fetch_Loop
    End
Close Production_Starts_Ins_Cursor
Deallocate Production_Starts_Ins_Cursor

GO
CREATE TRIGGER [dbo].[Production_Starts_History_Upd]
 ON  [dbo].[Production_Starts]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 416
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Production_Starts_History
 	  	   (Comment_Id,Confirmed,End_Time,Event_Subtype_Id,Prod_Id,PU_Id,Second_User_Id,Signature_Id,Start_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Confirmed,a.End_Time,a.Event_Subtype_Id,a.Prod_Id,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Start_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
