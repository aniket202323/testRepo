CREATE TABLE [dbo].[User_Defined_Events] (
    [UDE_Id]                    INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Ack]                       BIT                       CONSTRAINT [UserDefEvents_DF_Ack] DEFAULT ((0)) NOT NULL,
    [Ack_By]                    INT                       NULL,
    [Ack_On]                    DATETIME                  NULL,
    [Ack_On_Ms]                 SMALLINT                  CONSTRAINT [UDE_DF_AckOnMs] DEFAULT ((0)) NULL,
    [Action_Comment_Id]         INT                       NULL,
    [Action1]                   INT                       NULL,
    [Action2]                   INT                       NULL,
    [Action3]                   INT                       NULL,
    [Action4]                   INT                       NULL,
    [Cause_Comment_Id]          INT                       NULL,
    [Cause1]                    INT                       NULL,
    [Cause2]                    INT                       NULL,
    [Cause3]                    INT                       NULL,
    [Cause4]                    INT                       NULL,
    [Comment_Id]                INT                       NULL,
    [Duration]                  INT                       NULL,
    [End_Time]                  DATETIME                  NULL,
    [End_Time_Ms]               SMALLINT                  CONSTRAINT [UDE_DF_EndTimeMs] DEFAULT ((0)) NULL,
    [Event_Id]                  INT                       NULL,
    [Event_Reason_Tree_Data_Id] INT                       NULL,
    [Event_Subtype_Id]          INT                       NOT NULL,
    [EventSubCategory_Id]       INT                       NULL,
    [Historian_Quality_Id]      INT                       NULL,
    [Modified_On]               DATETIME                  NULL,
    [Modified_On_Ms]            SMALLINT                  CONSTRAINT [UDE_DF_ModifyedOnMs] DEFAULT ((0)) NULL,
    [NewEngUnitLabel]           [dbo].[Varchar_Eng_Units] NULL,
    [NewValue]                  [dbo].[Varchar_Value]     NULL,
    [OldEngUnitLabel]           [dbo].[Varchar_Eng_Units] NULL,
    [OldValue]                  [dbo].[Varchar_Value]     NULL,
    [OPCEventCategory_Id]       INT                       NULL,
    [OPCSeverity]               INT                       NULL,
    [Parent_UDE_Id]             INT                       NULL,
    [PU_Id]                     INT                       NULL,
    [Research_Close_Date]       DATETIME                  NULL,
    [Research_Comment_Id]       INT                       NULL,
    [Research_Open_Date]        DATETIME                  NULL,
    [Research_Status_Id]        INT                       NULL,
    [Research_User_Id]          INT                       NULL,
    [Signature_Id]              INT                       NULL,
    [Source_Id]                 INT                       NULL,
    [Start_Time]                DATETIME                  NULL,
    [Start_Time_Ms]             SMALLINT                  CONSTRAINT [UDE_DF_StartTimeMs] DEFAULT ((0)) NULL,
    [UDE_Desc]                  VARCHAR (1000)            NOT NULL,
    [User_Id]                   INT                       NULL,
    [Conformance]               TINYINT                   NULL,
    [Event_Status]              INT                       NULL,
    [Testing_Prct_Complete]     TINYINT                   NULL,
    [Testing_Status]            INT                       NULL,
    [Friendly_Desc]             VARCHAR (1000)            NULL,
    CONSTRAINT [UDE_PK_UDEId] PRIMARY KEY NONCLUSTERED ([UDE_Id] ASC),
    CONSTRAINT [UserDefinedEvents_CC_STimeETime] CHECK ([Start_Time]<=[End_Time] OR [End_Time] IS NULL OR [Start_Time] IS NULL),
    CONSTRAINT [UDE_FK_AckBy] FOREIGN KEY ([Ack_By]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UDE_FK_EventId] FOREIGN KEY ([Event_Id]) REFERENCES [dbo].[Events] ([Event_Id]),
    CONSTRAINT [UDE_FK_EventStatus] FOREIGN KEY ([Event_Status]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id]),
    CONSTRAINT [UDE_FK_EventSubTypeId] FOREIGN KEY ([Event_Subtype_Id]) REFERENCES [dbo].[Event_Subtypes] ([Event_Subtype_Id]),
    CONSTRAINT [UDE_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [UDE_FK_UDEId] FOREIGN KEY ([Parent_UDE_Id]) REFERENCES [dbo].[User_Defined_Events] ([UDE_Id]),
    CONSTRAINT [User_Def_Events_FK_RUserId] FOREIGN KEY ([Research_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UserDefEvents_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [UserDefinedEvents_FK_EventReasonId] FOREIGN KEY ([EventSubCategory_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [UserDefinedEvents_FK_EventReasonId1] FOREIGN KEY ([OPCEventCategory_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [UserDefinedEvents_FK_HistorianQualityId] FOREIGN KEY ([Historian_Quality_Id]) REFERENCES [dbo].[Historian_Quality] ([Historian_Quality_Id]),
    CONSTRAINT [UserDefinedEvents_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [UserDefinedEvents_FK_SourceID] FOREIGN KEY ([Source_Id]) REFERENCES [dbo].[Source] ([Source_Id])
);


GO
ALTER TABLE [dbo].[User_Defined_Events] NOCHECK CONSTRAINT [UDE_FK_EventId];


GO
CREATE CLUSTERED INDEX [UDE_IDX_PUIdESIdStartTime]
    ON [dbo].[User_Defined_Events]([PU_Id] ASC, [Event_Subtype_Id] ASC, [Start_Time] DESC, [Start_Time_Ms] DESC);


GO
CREATE NONCLUSTERED INDEX [UDE_IDX_SourceId]
    ON [dbo].[User_Defined_Events]([Source_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [UserDefinedEvents_IDX_ParentUDEId]
    ON [dbo].[User_Defined_Events]([Parent_UDE_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [UserDefinedEvents_IDX_EventId]
    ON [dbo].[User_Defined_Events]([Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [UDE_IDX_PUIdEndTime]
    ON [dbo].[User_Defined_Events]([PU_Id] ASC, [End_Time] DESC);


GO
CREATE NONCLUSTERED INDEX [UDE_Desc_EventSubtype_Index]
    ON [dbo].[User_Defined_Events]([UDE_Id] ASC, [Event_Subtype_Id] ASC, [UDE_Desc] ASC);


GO
CREATE NONCLUSTERED INDEX [UDE_IDX_UDEDescPUIdESTId]
    ON [dbo].[User_Defined_Events]([UDE_Desc] ASC, [PU_Id] ASC, [Event_Subtype_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [UDE_IDX_PUIdESIdEndTimeTestingstatus]
    ON [dbo].[User_Defined_Events]([PU_Id] ASC, [Event_Subtype_Id] ASC, [End_Time] ASC, [Testing_Status] ASC);


GO
CREATE TRIGGER dbo.User_Defined_Events_Del 
  ON dbo.User_Defined_Events 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int,
 	 @Comment_Id1 int,
 	 @Comment_Id2 int,
 	 @Comment_Id3 int,
 	 @Comment_Id4 int
  DECLARE User_Defined_Events_Del_Cursor CURSOR
    FOR SELECT UDE_Id, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id FROM DELETED
    FOR READ ONLY
  OPEN User_Defined_Events_Del_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM User_Defined_Events_Del_Cursor INTO @@Id, @Comment_Id1, @Comment_Id2, @Comment_Id3, @Comment_Id4
  IF @@FETCH_STATUS = 0
    BEGIN
 	     IF @Comment_Id1 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id1 
 	         Delete From Comments Where Comment_Id = @Comment_Id1 
 	       END
 	     IF @Comment_Id2 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id2
 	         Delete From Comments Where Comment_Id = @Comment_Id2
 	       END
 	     IF @Comment_Id3 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id3
 	         Delete From Comments Where Comment_Id = @Comment_Id3 
 	       END
 	     IF @Comment_Id4 IS NOT NULL 
 	       BEGIN
 	         Delete From Comments Where TopOfChain_Id = @Comment_Id4
 	         Delete From Comments Where Comment_Id = @Comment_Id4
 	       END
      Execute spServer_CmnRemoveScheduledTask @@Id,11
      GOTO Fetch_Next_Event
    END
  DEALLOCATE User_Defined_Events_Del_Cursor

GO
CREATE TRIGGER dbo.User_Defined_Events_Upd
  ON dbo.User_Defined_Events
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @Id int,
  @PUId int,
  @EndTime datetime
DECLARE User_Defined_Events_Upd_Cursor CURSOR
  FOR SELECT UDE_Id,PU_Id,End_Time  FROM INSERTED
  FOR READ ONLY
OPEN User_Defined_Events_Upd_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM User_Defined_Events_Upd_Cursor INTO @Id,@PUId,@EndTime
  IF @@FETCH_STATUS = 0
    BEGIN
 	  	  	 IF @EndTime Is not null
 	  	  	  	 Execute spServer_CmnAddScheduledTask @Id,11,@PUId,@EndTime
      GOTO Fetch_Next_Event
    END
  DEALLOCATE User_Defined_Events_Upd_Cursor

GO
CREATE TRIGGER [dbo].[User_Defined_Events_History_Upd]
 ON  [dbo].[User_Defined_Events]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 408
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into User_Defined_Event_History
 	  	   (Ack,Ack_By,Ack_On,Ack_On_Ms,Action_Comment_Id,Action1,Action2,Action3,Action4,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Comment_Id,Conformance,Duration,End_Time,End_Time_Ms,Event_Id,Event_Reason_Tree_Data_Id,Event_Status,Event_Subtype_Id,EventSubCategory_Id,Friendly_Desc,Historian_Quality_Id,User_Defined_Events_Modified_On,Modified_On_Ms,NewEngUnitLabel,NewValue,OldEngUnitLabel,OldValue,OPCEventCategory_Id,OPCSeverity,Parent_UDE_Id,PU_Id,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_Id,Start_Time,Start_Time_Ms,Testing_Prct_Complete,Testing_Status,UDE_Desc,UDE_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Ack,a.Ack_By,a.Ack_On,a.Ack_On_Ms,a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Comment_Id,a.Conformance,a.Duration,a.End_Time,a.End_Time_Ms,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.Event_Status,a.Event_Subtype_Id,a.EventSubCategory_Id,a.Friendly_Desc,a.Historian_Quality_Id,a.Modified_On,a.Modified_On_Ms,a.NewEngUnitLabel,a.NewValue,a.OldEngUnitLabel,a.OldValue,a.OPCEventCategory_Id,a.OPCSeverity,a.Parent_UDE_Id,a.PU_Id,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_Id,a.Start_Time,a.Start_Time_Ms,a.Testing_Prct_Complete,a.Testing_Status,a.UDE_Desc,a.UDE_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[User_Defined_Events_History_Ins]
 ON  [dbo].[User_Defined_Events]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 408
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into User_Defined_Event_History
 	  	   (Ack,Ack_By,Ack_On,Ack_On_Ms,Action_Comment_Id,Action1,Action2,Action3,Action4,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Comment_Id,Conformance,Duration,End_Time,End_Time_Ms,Event_Id,Event_Reason_Tree_Data_Id,Event_Status,Event_Subtype_Id,EventSubCategory_Id,Friendly_Desc,Historian_Quality_Id,User_Defined_Events_Modified_On,Modified_On_Ms,NewEngUnitLabel,NewValue,OldEngUnitLabel,OldValue,OPCEventCategory_Id,OPCSeverity,Parent_UDE_Id,PU_Id,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_Id,Start_Time,Start_Time_Ms,Testing_Prct_Complete,Testing_Status,UDE_Desc,UDE_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Ack,a.Ack_By,a.Ack_On,a.Ack_On_Ms,a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Comment_Id,a.Conformance,a.Duration,a.End_Time,a.End_Time_Ms,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.Event_Status,a.Event_Subtype_Id,a.EventSubCategory_Id,a.Friendly_Desc,a.Historian_Quality_Id,a.Modified_On,a.Modified_On_Ms,a.NewEngUnitLabel,a.NewValue,a.OldEngUnitLabel,a.OldValue,a.OPCEventCategory_Id,a.OPCSeverity,a.Parent_UDE_Id,a.PU_Id,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_Id,a.Start_Time,a.Start_Time_Ms,a.Testing_Prct_Complete,a.Testing_Status,a.UDE_Desc,a.UDE_Id,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.User_Defined_Events_Ins
  ON dbo.User_Defined_Events
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @Id int,
  @PUId int,
  @EndTime datetime
DECLARE User_Defined_Events_Ins_Cursor CURSOR
  FOR SELECT UDE_Id,PU_Id,End_Time FROM INSERTED
  FOR READ ONLY
OPEN User_Defined_Events_Ins_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM User_Defined_Events_Ins_Cursor INTO @Id,@PUId,@EndTime
  IF @@FETCH_STATUS = 0
    BEGIN
 	  	  	 IF @EndTime Is not null
 	  	  	  	 Execute spServer_CmnAddScheduledTask @Id,11,@PUId,@EndTime
      GOTO Fetch_Next_Event
    END
DEALLOCATE User_Defined_Events_Ins_Cursor

GO
CREATE TRIGGER [dbo].[User_Defined_Events_History_Del]
 ON  [dbo].[User_Defined_Events]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @ValidTrigger Bit
 Execute 	 spPDB_IsTriggerValid @ValidTrigger OUTPUT
 If @ValidTrigger = 0 Return
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 408
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into User_Defined_Event_History
 	  	   (Ack,Ack_By,Ack_On,Ack_On_Ms,Action_Comment_Id,Action1,Action2,Action3,Action4,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Comment_Id,Conformance,Duration,End_Time,End_Time_Ms,Event_Id,Event_Reason_Tree_Data_Id,Event_Status,Event_Subtype_Id,EventSubCategory_Id,Friendly_Desc,Historian_Quality_Id,User_Defined_Events_Modified_On,Modified_On_Ms,NewEngUnitLabel,NewValue,OldEngUnitLabel,OldValue,OPCEventCategory_Id,OPCSeverity,Parent_UDE_Id,PU_Id,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_Id,Start_Time,Start_Time_Ms,Testing_Prct_Complete,Testing_Status,UDE_Desc,UDE_Id,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Ack,a.Ack_By,a.Ack_On,a.Ack_On_Ms,a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Comment_Id,a.Conformance,a.Duration,a.End_Time,a.End_Time_Ms,a.Event_Id,a.Event_Reason_Tree_Data_Id,a.Event_Status,a.Event_Subtype_Id,a.EventSubCategory_Id,a.Friendly_Desc,a.Historian_Quality_Id,a.Modified_On,a.Modified_On_Ms,a.NewEngUnitLabel,a.NewValue,a.OldEngUnitLabel,a.OldValue,a.OPCEventCategory_Id,a.OPCSeverity,a.Parent_UDE_Id,a.PU_Id,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_Id,a.Start_Time,a.Start_Time_Ms,a.Testing_Prct_Complete,a.Testing_Status,a.UDE_Desc,a.UDE_Id,coalesce(@NEWUserId,a.User_Id),dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
