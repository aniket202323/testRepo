CREATE TABLE [dbo].[Events] (
    [Event_Id]              INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Applied_Product]       INT            NULL,
    [Approver_Reason_Id]    INT            NULL,
    [Approver_User_Id]      INT            NULL,
    [BOM_Formulation_Id]    BIGINT         NULL,
    [Comment_Id]            INT            NULL,
    [Confirmed]             BIT            CONSTRAINT [Events_DF_Confirmed] DEFAULT ((0)) NOT NULL,
    [Conformance]           TINYINT        NULL,
    [Consumed_Timestamp]    DATETIME       NULL,
    [Entry_On]              DATETIME       NULL,
    [Event_Num]             VARCHAR (50)   NOT NULL,
    [Event_Status]          INT            NULL,
    [Event_Subtype_Id]      INT            NULL,
    [Extended_Info]         VARCHAR (255)  NULL,
    [PU_Id]                 INT            NOT NULL,
    [Second_User_Id]        INT            NULL,
    [Signature_Id]          INT            NULL,
    [Source_Event]          INT            NULL,
    [Start_Time]            DATETIME       NULL,
    [Testing_Prct_Complete] TINYINT        NULL,
    [Testing_Status]        INT            CONSTRAINT [Events_DF_TestingStatus] DEFAULT ((1)) NULL,
    [TimeStamp]             DATETIME       NOT NULL,
    [User_Id]               INT            NULL,
    [User_Reason_Id]        INT            NULL,
    [User_Signoff_Id]       INT            NULL,
    [Lot_Identifier]        NVARCHAR (100) NULL,
    [Operation_Name]        NVARCHAR (100) NULL,
    CONSTRAINT [Events_PK_EventId] PRIMARY KEY NONCLUSTERED ([Event_Id] ASC),
    CONSTRAINT [Events_FK_AppProd] FOREIGN KEY ([Applied_Product]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Events_FK_BOM_Formulation_Id] FOREIGN KEY ([BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id]),
    CONSTRAINT [Events_FK_EventStatus] FOREIGN KEY ([Event_Status]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id]),
    CONSTRAINT [Events_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Events_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [EventsApproverReason_FK_Event_Reasons] FOREIGN KEY ([Approver_Reason_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [EventsApproverUserId_FK_Users] FOREIGN KEY ([Approver_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [EventsSecondUser_FK_Users] FOREIGN KEY ([Second_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [EventsUserReason_FK_Event_Reasons] FOREIGN KEY ([User_Reason_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [EventsUserSignoff_FK_Users] FOREIGN KEY ([User_Signoff_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Event_By_PU_And_Event_Number] UNIQUE NONCLUSTERED ([PU_Id] ASC, [Event_Num] ASC)
);


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [Events_FK_AppProd];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [Events_FK_BOM_Formulation_Id];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [Events_FK_PUId];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [Events_FK_SignatureID];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [EventsApproverReason_FK_Event_Reasons];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [EventsApproverUserId_FK_Users];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [EventsSecondUser_FK_Users];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [EventsUserReason_FK_Event_Reasons];


GO
ALTER TABLE [dbo].[Events] NOCHECK CONSTRAINT [EventsUserSignoff_FK_Users];


GO
CREATE UNIQUE CLUSTERED INDEX [Event_By_PU_And_TimeStamp]
    ON [dbo].[Events]([PU_Id] ASC, [TimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_PUID_EVENTID_APPLIEDPRODUCT]
    ON [dbo].[Events]([Applied_Product] ASC, [Event_Id] ASC, [PU_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_EVENTID_PUID_APPLIEDPRODUCT]
    ON [dbo].[Events]([Event_Id] ASC, [PU_Id] ASC)
    INCLUDE([Applied_Product]);


GO
CREATE NONCLUSTERED INDEX [EVENTPPID]
    ON [dbo].[Events]([Event_Id] ASC, [Applied_Product] ASC, [PU_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_EVENTNUM]
    ON [dbo].[Events]([Event_Num] ASC)
    INCLUDE([Applied_Product], [Event_Id], [Event_Status], [Lot_Identifier], [PU_Id], [TimeStamp]);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_LOT]
    ON [dbo].[Events]([Lot_Identifier] ASC)
    INCLUDE([Event_Id], [Extended_Info]);


GO
CREATE NONCLUSTERED INDEX [CLX_EVENTS_OP]
    ON [dbo].[Events]([Operation_Name] ASC, [Event_Id] ASC, [Extended_Info] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_APPPRODUCT_EVENTID_EVENTNUM_PUID]
    ON [dbo].[Events]([PU_Id] ASC)
    INCLUDE([Applied_Product], [Event_Id], [Event_Num]);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_PUID_TIMESTAMP_APPLIEDPRODUCT]
    ON [dbo].[Events]([PU_Id] ASC, [Applied_Product] ASC, [TimeStamp] ASC)
    INCLUDE([Event_Id], [Event_Status], [Lot_Identifier], [Operation_Name]);


GO
CREATE NONCLUSTERED INDEX [IX_EVENTS_PUID_TIMESTAMP]
    ON [dbo].[Events]([PU_Id] ASC, [TimeStamp] ASC)
    INCLUDE([Applied_Product], [Event_Id], [Event_Status], [Start_Time]);


GO
CREATE NONCLUSTERED INDEX [ix_Events_Event_Num]
    ON [dbo].[Events]([Event_Num] ASC, [Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Events_IDX_Event_Num]
    ON [dbo].[Events]([Event_Num] ASC);


GO
CREATE NONCLUSTERED INDEX [Events_IDX_Source_Event]
    ON [dbo].[Events]([Source_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_By_PU_And_Status]
    ON [dbo].[Events]([PU_Id] ASC, [Event_Status] ASC);


GO
CREATE TRIGGER dbo.Events_Ins
  ON dbo.Events
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	  	 Declare 
 	  	   @This_Time datetime,
 	  	   @This_Unit int,
 	  	   @This_EventId int,
 	  	   @This_Event_Num varchar(50),
 	  	   @This_Status int,
 	  	   @UserId  	    	  Int
  	    	  
 	  	 SELECT @UserId = MIN(User_Id) FROM Inserted
 	  	 IF @UserId = 49
  	  	  	  RETURN
 	  	 DECLARE Events_Ins_Cursor CURSOR
 	  	   FOR SELECT Event_Id, PU_Id, Event_Num, Timestamp, Event_Status FROM INSERTED
 	  	   FOR READ ONLY
 	  	 OPEN Events_Ins_Cursor
 	  	   Fetch_Next_Event:
 	  	   FETCH NEXT FROM Events_Ins_Cursor INTO @This_EventId, @This_Unit, @This_Event_Num, @This_Time, @This_Status
 	  	   IF @@FETCH_STATUS = 0
 	  	  	 BEGIN
 	  	  	   Delete From PREEvents Where (PU_Id = @This_Unit) And (Event_Num = @This_Event_Num)
 	  	  	   Execute spServer_CmnAddScheduledTask @This_EventId,1,@This_Unit,@This_Time,@This_Status
 	  	  	  	   Select @This_EventId = NULL
 	  	  	  	   Select @This_EventId = Event_Id, @This_Status = Event_Status , @This_Time = Timestamp
      	  	  	  From Events 
      	  	  	  where (pu_id = @This_Unit) and 
  	  	  	  	    (TimeStamp = (select min(TimeStamp) from Events where (pu_id = @This_Unit) and (TimeStamp > @This_Time)))
 	  	  	   If (@This_EventId Is Not NULL)
 	  	  	  	 Begin
 	  	  	  	   Execute spServer_CmnAddScheduledTask @This_EventId,1,@This_Unit,@This_Time,@This_Status
 	  	  	  	 End
 	  	  	   GOTO Fetch_Next_Event
 	  	  	 END
 	  	   ELSE IF @@FETCH_STATUS <> -1
 	  	  	 BEGIN
 	  	  	   RAISERROR('Fetch error in Event_Ins (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
 	  	  	 END
 	  	 DEALLOCATE Events_Ins_Cursor

GO
CREATE TRIGGER dbo.Events_Upd
  ON dbo.Events
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	  	 Declare 
 	  	   @This_Time datetime,
 	  	   @This_StartTime datetime,
 	  	   @This_Unit int,
 	  	   @This_Event_Num varchar(50),
 	  	   @This_Status int,
 	  	   @This_Applied_Product int,
 	  	   @This_UserSignoffId int,
 	  	   @This_ApproverId int,
 	  	   @This_EventId int,
 	  	   @Deleted_Time datetime,
 	  	   @Deleted_StartTime datetime,
 	  	   @Deleted_Status int,
 	  	   @Deleted_Applied_Product int,
 	  	   @Deleted_UserSignoffId int,
 	  	   @Deleted_ApproverId int,
 	  	   @Time_Flag tinyint,
 	  	   @ScheduleTime_Flag int, 
 	  	   @Start_Time_Flag tinyint,
 	  	   @Status_Flag tinyint,
 	  	   @Applied_Product_Flag tinyint,
 	  	   @UserSignoffId_Flag tinyint,
 	  	   @ApproverId_Flag tinyint,
 	  	   @UserId   	      	   Int
   	      	   
 	  	 SELECT @UserId = MIN(User_Id) FROM Inserted
 	  	 IF @UserId = 49
   	  	  	   RETURN
 	  	 DECLARE Events_Upd_Cursor CURSOR
 	  	   FOR SELECT Event_Id,PU_Id, Event_Num, Start_Time, Timestamp, Event_Status, Applied_Product, User_Signoff_Id, Approver_User_Id FROM INSERTED
 	  	   FOR READ ONLY
 	  	 OPEN Events_Upd_Cursor
 	  	   Fetch_Next_Event:
 	  	   FETCH NEXT FROM Events_Upd_Cursor INTO @This_EventId,@This_Unit, @This_Event_Num, @This_StartTime, @This_Time, @This_Status, @This_Applied_Product, @This_UserSignoffId, @This_ApproverId
 	  	   IF @@FETCH_STATUS = 0
 	  	  	 BEGIN
 	  	  	   Delete From Preevents Where (PU_Id = @This_Unit) And (Event_Num = @This_Event_Num)
 	  	  	   Select @Deleted_StartTime = Start_Time,
 	  	  	  	  	  @Deleted_Time = TimeStamp,
 	  	  	  	  	  @Deleted_Status = Event_Status,
 	  	  	  	  	  @Deleted_Applied_Product = Applied_Product,
 	  	  	  	  	  @Deleted_UserSignoffId = User_Signoff_Id,
 	  	  	  	  	  @Deleted_ApproverId = Approver_User_Id
 	  	  	  	 From DELETED
 	  	  	  	 Where (Event_Id = @This_EventId)
 	  	  	   Select @Time_Flag = 0
 	  	  	   If (@Deleted_Time Is NULL) Or (@This_Time Is NULL)
 	  	  	  	 Begin
 	  	  	  	   If NOT((@Deleted_Time Is NULL) And (@This_Time Is NULL))
 	  	  	  	  	 Select @Time_Flag = 1
 	  	  	  	 End
 	  	  	   Else
         	  	  	   If (@Deleted_Time <> @This_Time)
 	  	  	  	   Select @Time_Flag = 1
 	  	  	   Select @Start_Time_Flag = 0 
   	  	  	  	 If @Time_Flag = 0 
 	  	  	  	 Begin
 	  	  	  	   If (@Deleted_StartTime Is NULL) Or (@This_StartTime Is NULL)
 	  	  	  	  	 Begin
 	  	  	  	  	   If NOT((@Deleted_StartTime Is NULL) And (@This_StartTime Is NULL))
 	  	  	  	  	  	 Select @Start_Time_Flag = 1
 	  	  	  	  	 End
 	  	  	  	   Else
         	  	  	  	   If (@Deleted_StartTime <> @This_StartTime)
 	  	  	  	  	   Select @Start_Time_Flag = 1
 	  	  	  	 End
   	  	  	  	 If @Time_Flag = 0 and @Start_Time_Flag = 0 
 	  	  	  	 Begin
 	  	  	  	   Select @Status_Flag = 0
 	  	  	  	   If (@Deleted_Status Is NULL) Or (@This_Status Is NULL)
 	  	  	  	  	 Begin
 	  	  	  	  	   If NOT((@Deleted_Status Is NULL) And (@This_Status Is NULL))
 	  	  	  	  	  	 Select @Status_Flag = 1
 	  	  	  	  	 End
 	  	  	  	   Else
             	  	  	   If (@Deleted_Status <> @This_Status)
 	  	  	  	  	   Select @Status_Flag = 1
 	  	  	  	 End
   	  	  	  	 If @Time_Flag = 0 and @Start_Time_Flag = 0 and @Status_Flag = 0
 	  	  	  	 Begin
 	  	  	  	   Select @Applied_Product_Flag = 0
 	  	  	  	   If (@Deleted_Applied_Product Is NULL) Or (@This_Applied_Product Is NULL)
 	  	  	  	  	 Begin
 	  	  	  	  	   If NOT((@Deleted_Applied_Product Is NULL) And (@This_Applied_Product Is NULL))
 	  	  	  	  	  	 Select @Applied_Product_Flag = 1
 	  	  	  	  	 End
 	  	  	  	   Else
             	  	  	   If (@Deleted_Applied_Product <> @This_Applied_Product)
 	  	  	  	  	   Select @Applied_Product_Flag = 1
 	  	  	  	 End
 	  	  	 If @Time_Flag = 0 and @Start_Time_Flag = 0 and @Status_Flag = 0 and @Applied_Product_Flag = 0
 	  	  	  	 Begin
 	  	  	  	   Select @UserSignoffId_Flag = 0
 	  	  	  	   If (@Deleted_UserSignoffId Is NULL) Or (@This_UserSignoffId Is NULL)
 	  	  	  	  	 Begin
 	  	  	  	  	   If NOT((@Deleted_UserSignoffId Is NULL) And (@This_UserSignoffId Is NULL))
 	  	  	  	  	  	 Select @UserSignoffId_Flag = 1
 	  	  	  	  	 End
 	  	  	  	   Else
             	  	  	   If (@Deleted_UserSignoffId <> @This_UserSignoffId)
 	  	  	  	  	   Select @UserSignoffId_Flag = 1
 	  	  	  	 End
 	  	  	 If @Time_Flag = 0 and @Start_Time_Flag = 0 and @Status_Flag = 0 and @Applied_Product_Flag = 0 and @UserSignoffId_Flag = 0
 	  	  	  	 Begin
 	  	  	  	   Select @ApproverId_Flag = 0
 	  	  	  	   If (@Deleted_ApproverId Is NULL) Or (@This_ApproverId Is NULL)
 	  	  	  	  	 Begin
 	  	  	  	  	   If NOT((@Deleted_ApproverId Is NULL) And (@This_ApproverId Is NULL))
 	  	  	  	  	  	 Select @ApproverId_Flag = 1
 	  	  	  	  	 End
 	  	  	  	   Else
             	  	  	   If (@Deleted_ApproverId <> @This_ApproverId)
 	  	  	  	  	   Select @ApproverId_Flag = 1
 	  	  	  	 End
 	  	  	   If ((@Time_Flag = 1) Or (@Status_Flag = 1) Or (@Applied_Product_Flag = 1) Or @Start_Time_Flag = 1 or (@UserSignoffId_Flag = 1) or (@ApproverId_Flag = 1))
 	  	  	  	 Begin
 	  	  	  	   If ((@Time_Flag = 0) and (@Start_Time_Flag = 0)) 
 	  	  	  	  	 Select @ScheduleTime_Flag = 0
 	  	  	  	   Else
 	  	  	  	  	 Select @ScheduleTime_Flag = 1
  	    	    	  	  	  Execute spServer_CmnAddScheduledTask @This_EventId,1,@This_Unit,@This_Time, @This_Status, @ScheduleTime_Flag,@Deleted_Status,@Deleted_Applied_Product,null,@Applied_Product_Flag
   	      	      	      	      	  	  	   If (@Time_Flag = 1)
   	      	      	      	      	  	  	   Begin
   	      	      	      	      	      	  	  	   IF EXISTS(SELECT 1 FROM Prod_Units_Base WHERE pu_id = @This_Unit and Chain_Start_Time = 1)
   	      	      	      	      	      	  	  	   BEGIN
   	      	      	      	      	      	      	  	  	   Select @This_EventId = NULL
   	      	      	      	      	      	      	  	  	   Select @This_EventId = Event_Id, @This_Status = Event_Status , @This_Time = timestamp
   	      	      	      	      	      	      	  	  	   from Events 
   	      	      	      	      	      	      	  	  	   where (pu_id = @This_Unit) and 
   	      	      	      	      	      	      	  	  	   (TimeStamp = (select min(TimeStamp) from Events where (pu_id = @This_Unit) and (TimeStamp > @This_Time)))
   	      	      	      	      	      	      	  	  	   If (@This_EventId Is Not NULL)
   	      	      	      	      	      	      	  	  	   Begin
   	      	      	      	      	      	      	      	  	  	   Execute spServer_CmnAddScheduledTask @This_EventId,1,@This_Unit,@This_Time, @This_Status, @Time_Flag,@This_Status,null,null,@Applied_Product_Flag
   	      	      	      	      	      	      	  	  	   End
   	      	      	      	      	      	  	  	   END
   	      	      	      	      	  	  	   End
 	  	  	  	 End
 	  	  	   GOTO Fetch_Next_Event
 	  	  	 END
 	  	   ELSE IF @@FETCH_STATUS <> -1
 	  	  	 BEGIN
 	  	  	   RAISERROR('Fetch error in Events_Upd (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
 	  	  	 END
 	  	   DEALLOCATE Events_Upd_Cursor

GO
CREATE TRIGGER dbo.Events_Del_StatTrans 
  ON dbo.Events 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE 	 @This_Time 	  	  	 DATETIME,
 	  	  	 @This_Unit 	  	  	 INT,
 	  	  	 @This_Event_Num 	 VARCHAR(50),
 	  	  	 @This_Id 	  	  	  	 INT,
 	  	  	 @NextId 	  	  	  	 INT,
 	  	  	 @NextTime 	  	  	 DATETIME
 	  	  	 
DELETE 	 Event_Status_Transitions
 	 FROM 	 Event_Status_Transitions est JOIN
 	  	  	 DELETED d ON (est.Event_id = d.Event_Id)

GO
CREATE TRIGGER [dbo].[Events_History_Ins]
 ON  [dbo].[Events]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 413
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Event_History
 	  	   (Applied_Product,Approver_Reason_Id,Approver_User_Id,BOM_Formulation_Id,Comment_Id,Confirmed,Conformance,Consumed_Timestamp,Entry_On,Event_Id,Event_Num,Event_Status,Event_Subtype_Id,Extended_Info,Lot_Identifier,Operation_Name,PU_Id,Second_User_Id,Signature_Id,Source_Event,Start_Time,Testing_Prct_Complete,Testing_Status,TimeStamp,User_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Applied_Product,a.Approver_Reason_Id,a.Approver_User_Id,a.BOM_Formulation_Id,a.Comment_Id,a.Confirmed,a.Conformance,a.Consumed_Timestamp,a.Entry_On,a.Event_Id,a.Event_Num,a.Event_Status,a.Event_Subtype_Id,a.Extended_Info,a.Lot_Identifier,a.Operation_Name,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Source_Event,a.Start_Time,a.Testing_Prct_Complete,a.Testing_Status,a.TimeStamp,a.User_Id,a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Events_History_Del]
 ON  [dbo].[Events]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 413
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Event_History
 	  	   (Applied_Product,Approver_Reason_Id,Approver_User_Id,BOM_Formulation_Id,Comment_Id,Confirmed,Conformance,Consumed_Timestamp,Entry_On,Event_Id,Event_Num,Event_Status,Event_Subtype_Id,Extended_Info,Lot_Identifier,Operation_Name,PU_Id,Second_User_Id,Signature_Id,Source_Event,Start_Time,Testing_Prct_Complete,Testing_Status,TimeStamp,User_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Applied_Product,a.Approver_Reason_Id,a.Approver_User_Id,a.BOM_Formulation_Id,a.Comment_Id,a.Confirmed,a.Conformance,a.Consumed_Timestamp,a.Entry_On,a.Event_Id,a.Event_Num,a.Event_Status,a.Event_Subtype_Id,a.Extended_Info,a.Lot_Identifier,a.Operation_Name,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Source_Event,a.Start_Time,a.Testing_Prct_Complete,a.Testing_Status,a.TimeStamp,coalesce(@NEWUserId,a.User_Id),a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Events_InsUpd_StatTrans
 	 ON dbo.Events
 	 FOR INSERT, UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	  	 DECLARE   	   @This_EntryOn   	      	      	      	      	   DATETIME,
   	      	      	  	  	   @This_Status   	      	      	      	      	  INT,
   	      	      	  	  	   @This_EventId   	      	      	      	      	   INT,
   	      	      	  	  	   @This_PUId   	      	      	      	      	   INT,
   	      	      	  	  	   @Deleted_EntryOn   	      	      	      	   DATETIME,
   	      	      	  	  	   @Deleted_Status   	      	      	      	   INT,
   	      	      	  	  	   @CurrentId   	      	      	      	      	      	   INT,
   	      	      	  	  	   @CurrentStartTime  	    	    	  DateTime,
  	    	    	  	  	  @TestId  	    	    	    	    	    	  INT,
  	    	    	  	  	  @ThisStartTime  	    	    	    	  DATETIME,
  	    	    	  	  	  @UserId  	    	  Int
  	    	  
 	  	 SELECT @UserId = MIN(User_Id) FROM Inserted
 	  	 IF @UserId = 49
  	  	  	  RETURN
 	  	 DECLARE   	   Events_InsUpd_StatTrans_Cursor CURSOR
   	  	  	   FOR   	   SELECT   	   Event_Id,Event_Status,Entry_On,Start_Time,PU_Id
   	      	      	      	  	  	   FROM   	   INSERTED
   	  	  	   FOR READ ONLY
 	  	 OPEN Events_InsUpd_StatTrans_Cursor
 	  	 Fetch_Next_Event:
   	  	  	   SELECT   	   @This_EventId = NULL, @This_Status = NULL, @This_EntryOn = NULL,@ThisStartTime =Null,@This_PUId = NULL
   	  	  	   FETCH NEXT FROM Events_InsUpd_StatTrans_Cursor INTO @This_EventId,@This_Status,@This_EntryOn,@ThisStartTime,@This_PUId
   	  	  	   IF @@FETCH_STATUS = 0
   	  	  	   BEGIN
   	      	  	  	   SELECT   	   @Deleted_EntryOn = NULL, 
   	      	      	      	      	  	  	   @Deleted_Status =  NULL
   	      	  	  	   SELECT   	   @Deleted_EntryOn = Entry_On,
   	      	      	      	      	  	  	   @Deleted_Status = Event_Status
   	      	      	  	  	   FROM   	   DELETED
   	      	      	  	  	   WHERE   	   (Event_Id = @This_EventId)
   	      	  	  	   IF (@This_Status <> @Deleted_Status) OR (@Deleted_Status IS NULL)
   	      	  	  	   BEGIN
   	      	      	  	  	   SELECT   	   @CurrentId = NULL
   	      	      	  	  	   SELECT   	   @CurrentId = EST_Id,@CurrentStartTime = Start_Time 
   	      	      	      	  	  	   FROM   	   Event_Status_Transitions
   	      	      	      	  	  	   WHERE   	   Event_Id = @This_EventId AND
   	      	      	      	      	      	  	  	   End_Time IS NULL
   	      	      	  	  	   SELECT   	   @TestId = NULL
   	      	      	  	  	   SELECT   	   @TestId = EST_Id 
   	      	      	      	  	  	   FROM   	   Event_Status_Transitions 
   	      	      	      	  	  	   WHERE   	   Event_Id = @This_EventId AND 
   	      	      	      	      	      	  	  	   Start_Time = @This_EntryOn
   	      	      	  	  	   IF (@TestId IS NOT NULL) AND (@Deleted_Status IS NOT NULL)
   	      	      	  	  	   BEGIN
   	      	      	    	  	  	  -- already a transation at this time - use current time
    	      	    	    	  	  	  SET @This_EntryOn = dbo.fnServer_CmnGetDate(getUTCdate())
   	      	      	  	  	   END
   	      	      	  	  	   IF @CurrentId IS NOT NULL
   	      	      	  	  	   BEGIN
  	    	    	    	  	  	  IF @CurrentStartTime > @This_EntryOn 
  	    	    	    	    	  	  	  SET @This_EntryOn = @CurrentStartTime
   	      	      	      	  	  	   UPDATE   	   Event_Status_Transitions
   	      	      	      	      	  	  	   SET   	   End_Time = @This_EntryOn
   	      	      	      	      	  	  	   WHERE   	   EST_Id = @CurrentId
    	      	    	    	  	  	  SET @ThisStartTime = @This_EntryOn
   	      	      	  	  	   END
   	      	      	  	  	   ELSE
   	      	      	  	  	   BEGIN
   	      	      	    	  	  	  -- use starttime if first record
    	      	    	    	  	  	  SET @ThisStartTime = Coalesce(@ThisStartTime,@This_EntryOn,dbo.fnServer_CmnGetDate(getUTCdate()))
   	      	      	  	  	   END
  	      	      	  	  	   INSERT INTO Event_Status_Transitions (Event_Id, Event_Status, Start_Time, PU_Id)
   	      	      	      	  	  	   VALUES (@This_EventId, @This_Status, @ThisStartTime, @This_PUId)
   	      	  	  	   END
   	      	  	  	   GOTO Fetch_Next_Event
   	  	  	   END
   	  	  	   ELSE IF @@FETCH_STATUS <> -1
   	  	  	   BEGIN
 	  	  	   RAISERROR('Fetch error in Events_InsUpd_StatTrans (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
   	  	  	   END
   	  	  	   DEALLOCATE Events_InsUpd_StatTrans_Cursor

GO
CREATE TRIGGER [dbo].[Events_History_Upd]
 ON  [dbo].[Events]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 413
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Event_History
 	  	   (Applied_Product,Approver_Reason_Id,Approver_User_Id,BOM_Formulation_Id,Comment_Id,Confirmed,Conformance,Consumed_Timestamp,Entry_On,Event_Id,Event_Num,Event_Status,Event_Subtype_Id,Extended_Info,Lot_Identifier,Operation_Name,PU_Id,Second_User_Id,Signature_Id,Source_Event,Start_Time,Testing_Prct_Complete,Testing_Status,TimeStamp,User_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Applied_Product,a.Approver_Reason_Id,a.Approver_User_Id,a.BOM_Formulation_Id,a.Comment_Id,a.Confirmed,a.Conformance,a.Consumed_Timestamp,a.Entry_On,a.Event_Id,a.Event_Num,a.Event_Status,a.Event_Subtype_Id,a.Extended_Info,a.Lot_Identifier,a.Operation_Name,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Source_Event,a.Start_Time,a.Testing_Prct_Complete,a.Testing_Status,a.TimeStamp,a.User_Id,a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
If (@Populate_History = 3)
   Begin
 	  	 DECLARE @InsertedEvents Table(id int identity(1,1),EventId int,EventStatus Int,NoHistory Int,UserId Int)
 	  	 INSERT INTO @InsertedEvents(EventId,EventStatus,NoHistory,UserId)
 	  	  	 SELECT  Event_Id, Event_Status,NoHistory,User_Id 
 	  	  	  	 FROM inserted a
 	  	  	  	 JOIN Production_Status b on a.Event_Status = b.ProdStatus_Id
 	  	 DELETE FROM @InsertedEvents
 	  	  	 FROM @InsertedEvents a
 	  	  	 JOIN Deleted b on b.Event_Id = a.EventId
 	  	  	 WHERE NoHistory = 1 and a.EventStatus = b.Event_Status And Userid Between 2 and 50
 	  	   Insert Into Event_History
 	  	   (Applied_Product,Approver_Reason_Id,Approver_User_Id,BOM_Formulation_Id,Comment_Id,Confirmed,Conformance,Consumed_Timestamp,Entry_On,Event_Id,Event_Num,Event_Status,Event_Subtype_Id,Extended_Info,Lot_Identifier,Operation_Name,PU_Id,Second_User_Id,Signature_Id,Source_Event,Start_Time,Testing_Prct_Complete,Testing_Status,TimeStamp,User_Id,User_Reason_Id,User_Signoff_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Applied_Product,a.Approver_Reason_Id,a.Approver_User_Id,a.BOM_Formulation_Id,a.Comment_Id,a.Confirmed,a.Conformance,a.Consumed_Timestamp,a.Entry_On,a.Event_Id,a.Event_Num,a.Event_Status,a.Event_Subtype_Id,a.Extended_Info,a.Lot_Identifier,a.Operation_Name,a.PU_Id,a.Second_User_Id,a.Signature_Id,a.Source_Event,a.Start_Time,a.Testing_Prct_Complete,a.Testing_Status,a.TimeStamp,a.User_Id,a.User_Reason_Id,a.User_Signoff_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a 
 	  	   JOIN @InsertedEvents b on b.EventId = a.Event_Id
End 

GO
CREATE TRIGGER dbo.Events_Del 
  ON dbo.Events 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
  @This_Time datetime,
  @This_Unit int,
  @This_Event_Num varchar(50),
  @This_Id int,
  @NextId int,
  @NextTime datetime,
 	 @Comment_Id int
--
--
  DECLARE Events_Del_Cursor CURSOR
    FOR SELECT Event_Id, PU_Id, Event_Num, Timestamp, Comment_Id FROM DELETED
    FOR READ ONLY
  OPEN Events_Del_Cursor
--
--
  Fetch_Next_Event:
  FETCH NEXT FROM Events_Del_Cursor INTO @This_Id, @This_Unit, @This_Event_Num, @This_Time, @Comment_Id
  IF @@FETCH_STATUS = 0
    BEGIN
 	  	 If @Comment_Id is NOT NULL 
 	  	  	 BEGIN
 	  	  	  	   Delete From Comments Where TopOfChain_Id = @Comment_Id 
   	  	  	  	 Delete From Comments Where Comment_Id = @Comment_Id 
 	  	  	 END
 	   Execute spServer_CmnRemoveScheduledTask @This_Id,1
 	   Select @NextId = NULL
 	   Select @NextId = Event_Id, @NextTime = Timestamp from Events
          where (pu_id = @This_Unit) and (TimeStamp = (select min(TimeStamp) from Events where pu_id = @This_Unit and TimeStamp > @This_Time and (event_status >= 5))) and
                (Event_Id NOT IN (SELECT Event_Id FROM DELETED))
 	   If (@NextId Is Not NULL)
 	     Execute spServer_CmnAddScheduledTask @NextId,1,@This_Unit,@NextTime
      delete from preevents
        where (PU_Id = @This_Unit) And (Event_Num = @This_Event_Num)
      GOTO Fetch_Next_Event
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error in Event_Del (@@FETCH_STATUS = %d).', 11,
        -1, @@FETCH_STATUS)
    END
  DEALLOCATE Events_Del_Cursor

GO
CREATE TRIGGER [dbo].[Events_InsUpd_PUTrans]
  	  ON [dbo].[Events]
  	  FOR  UPDATE
  	  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE  	  @This_PUId  	    	    	 INT,
  	    	    	  @This_EventId  	    	    	 INT,
  	    	    	  @Deleted_StartTime  	 DATETIME,
  	    	    	  @Deleted_EndTime  	    	 DATETIME,
  	    	    	  @Deleted_PUId  	    	    	 INT,
  	    	    	  @CheckId  	    	    	    	 INT,
  	    	    	  @OldEndTime  	    	    	 DATETIME,
  	    	    	  @UserId  	    	  	  	 INT
  	    	  
SELECT @UserId = MIN(User_Id) FROM Inserted
IF @UserId = 49
  	  RETURN
DECLARE  	  Events_InsUpd_PUTrans_Cursor CURSOR
  	  FOR  	  SELECT  	  Event_Id,PU_Id
  	    	    	    	  FROM  	  INSERTED
  	  FOR READ ONLY
OPEN Events_InsUpd_PUTrans_Cursor
Fetch_Next_Event:
  	  SELECT  	  @This_EventId = NULL, @This_PUId = NULL
  	  FETCH NEXT FROM Events_InsUpd_PUTrans_Cursor INTO @This_EventId,@This_PUId
  	  IF @@FETCH_STATUS = 0
  	  BEGIN
  	    	  SELECT  	  @Deleted_PUId 	  	 =  NULL,
  	    	    	    	    	  @Deleted_StartTime =  NULL,
  	    	    	    	    	  @Deleted_EndTime   =  NULL
  	    	  SELECT  	  @Deleted_PUId = PU_Id,
  	    	    	    	    	  @Deleted_StartTime = Start_Time,
  	    	    	    	    	  @Deleted_EndTime = TimeStamp  	    	    	    	    	  
  	    	    	  FROM  	  DELETED
  	    	    	  WHERE  	  (Event_Id = @This_EventId)
 	  	 IF @Deleted_PUId Is Not Null
 	  	 BEGIN
 	  	  	 IF (@This_PUId <> @Deleted_PUId)
 	  	  	 BEGIN
 	  	  	  	 SELECT @OldEndTime = NULL
 	  	  	  	 SELECT @OldEndTime = Max(End_Time)
 	  	  	  	  	 FROM Event_PU_Transitions
 	  	  	  	  	 WHERE Event_Id = @This_EventId
 	  	  	  	 SELECT  @Deleted_StartTime = Coalesce(@Deleted_StartTime,@OldEndTime,@Deleted_EndTime)
 	  	  	  	 IF @Deleted_EndTime >  @OldEndTime or @OldEndTime Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO Event_PU_Transitions (Event_Id, PU_Id, Start_Time,End_Time,Modified_on)
 	  	  	  	  	  	 SELECT @This_EventId, @Deleted_PUId, @Deleted_StartTime,@Deleted_EndTime,dbo.fnServer_cmnGetDate(getUTCdate())
 	  	  	  	 END
 	  	  	 END 	 
 	  	 END
  	    	  GOTO Fetch_Next_Event
  	  END
  	  DEALLOCATE Events_InsUpd_PUTrans_Cursor
