CREATE TABLE [dbo].[Alarms] (
    [Alarm_Id]                  INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Ack]                       BIT                       CONSTRAINT [Alarms_DF_Ack] DEFAULT ((0)) NOT NULL,
    [Ack_By]                    INT                       NULL,
    [Ack_Comment_ID]            INT                       NULL,
    [Ack_On]                    DATETIME                  NULL,
    [Ack_On_Ms]                 SMALLINT                  CONSTRAINT [Alarms_DF_AckOnMs] DEFAULT ((0)) NULL,
    [Action_Comment_Id]         INT                       NULL,
    [Action1]                   INT                       NULL,
    [Action2]                   INT                       NULL,
    [Action3]                   INT                       NULL,
    [Action4]                   INT                       NULL,
    [Alarm_Desc]                VARCHAR (1000)            NOT NULL,
    [Alarm_Type_Id]             INT                       NOT NULL,
    [ATD_Id]                    INT                       NULL,
    [ATSRD_Id]                  INT                       NULL,
    [ATVRD_Id]                  INT                       NULL,
    [Cause_Comment_Id]          INT                       NULL,
    [Cause1]                    INT                       NULL,
    [Cause2]                    INT                       NULL,
    [Cause3]                    INT                       NULL,
    [Cause4]                    INT                       NULL,
    [Cutoff]                    TINYINT                   NULL,
    [Data_Type_Id]              INT                       NULL,
    [Duration]                  INT                       NULL,
    [End_Result]                [dbo].[Varchar_Value]     NULL,
    [End_Time]                  DATETIME                  NULL,
    [End_Time_Ms]               SMALLINT                  CONSTRAINT [Alarms_DF_EndTimeMS] DEFAULT ((0)) NULL,
    [EngUnitLabel]              [dbo].[Varchar_Eng_Units] NULL,
    [Event_Reason_Tree_Data_Id] INT                       NULL,
    [EventSubCategory_Id]       INT                       NULL,
    [Historian_Quality_Id]      INT                       NULL,
    [Key_Id]                    INT                       NULL,
    [Max_Result]                [dbo].[Varchar_Value]     NULL,
    [Min_Result]                [dbo].[Varchar_Value]     NULL,
    [Modified_On]               DATETIME                  NULL,
    [Modified_On_Ms]            SMALLINT                  CONSTRAINT [Alarms_DF_ModifyedOnMs] DEFAULT ((0)) NULL,
    [OPCCondition_Id]           INT                       NULL,
    [OPCEventCategory_Id]       INT                       NULL,
    [OPCSeverity]               INT                       NULL,
    [OPCSubCondition_Id]        INT                       NULL,
    [Path_Id]                   INT                       NULL,
    [Research_Close_Date]       DATETIME                  NULL,
    [Research_Comment_Id]       INT                       NULL,
    [Research_Open_Date]        DATETIME                  NULL,
    [Research_Status_Id]        INT                       NULL,
    [Research_User_Id]          INT                       NULL,
    [Signature_Id]              INT                       NULL,
    [Source_Id]                 INT                       NULL,
    [Source_PU_Id]              INT                       NULL,
    [Start_Result]              [dbo].[Varchar_Value]     NULL,
    [Start_Time]                DATETIME                  NOT NULL,
    [Start_Time_Ms]             SMALLINT                  CONSTRAINT [Alarms_DF_StartTimeMs] DEFAULT ((0)) NULL,
    [SubType]                   INT                       NULL,
    [User_Id]                   INT                       NOT NULL,
    CONSTRAINT [Alarms_PK_AlarmId] PRIMARY KEY NONCLUSTERED ([Alarm_Id] ASC),
    CONSTRAINT [Alarms_FK_AckUser] FOREIGN KEY ([Ack_By]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Alarms_FK_Alarm_Types] FOREIGN KEY ([Alarm_Type_Id]) REFERENCES [dbo].[Alarm_Types] ([Alarm_Type_Id]),
    CONSTRAINT [Alarms_FK_ATDId] FOREIGN KEY ([ATD_Id]) REFERENCES [dbo].[Alarm_Template_Var_Data] ([ATD_Id]),
    CONSTRAINT [Alarms_FK_ATSRDId] FOREIGN KEY ([ATSRD_Id]) REFERENCES [dbo].[Alarm_Template_SPC_Rule_Data] ([ATSRD_Id]),
    CONSTRAINT [Alarms_FK_ATVRDId] FOREIGN KEY ([ATVRD_Id]) REFERENCES [dbo].[Alarm_Template_Variable_Rule_Data] ([ATVRD_Id]),
    CONSTRAINT [Alarms_FK_DataTypeId] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id]),
    CONSTRAINT [Alarms_FK_EventReasonsOPCC] FOREIGN KEY ([OPCCondition_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Alarms_FK_EventReasonsOPCEC] FOREIGN KEY ([OPCEventCategory_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Alarms_FK_EventReasonsOPCES] FOREIGN KEY ([EventSubCategory_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Alarms_FK_EventReasonsOPCS] FOREIGN KEY ([OPCSubCondition_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Alarms_FK_HistorianQualityId] FOREIGN KEY ([Historian_Quality_Id]) REFERENCES [dbo].[Historian_Quality] ([Historian_Quality_Id]),
    CONSTRAINT [Alarms_FK_Paths] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [Alarms_FK_RUsers] FOREIGN KEY ([Research_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Alarms_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [Alarms_FK_SourceID] FOREIGN KEY ([Source_Id]) REFERENCES [dbo].[Source] ([Source_Id]),
    CONSTRAINT [Alarms_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE CLUSTERED INDEX [Alarms_IX_AlarmTime]
    ON [dbo].[Alarms]([Start_Time] DESC, [Start_Time_Ms] DESC, [Modified_On] DESC, [Modified_On_Ms] DESC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_SourceConditionStart]
    ON [dbo].[Alarms]([Source_Id] ASC, [OPCCondition_Id] ASC, [Start_Time] ASC, [Start_Time_Ms] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_ATSRD_Id]
    ON [dbo].[Alarms]([ATSRD_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IDX_PathId]
    ON [dbo].[Alarms]([Path_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_EndTime]
    ON [dbo].[Alarms]([End_Time] ASC, [End_Time_Ms] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_StartEnd]
    ON [dbo].[Alarms]([Start_Time] ASC, [End_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_AlarmSourceCondition]
    ON [dbo].[Alarms]([Source_Id] ASC, [OPCCondition_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_Unq_KeyTypeATDStart]
    ON [dbo].[Alarms]([Key_Id] ASC, [Alarm_Type_Id] ASC, [ATD_Id] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_SourceConditionEnd]
    ON [dbo].[Alarms]([Source_Id] ASC, [OPCCondition_Id] ASC, [End_Time] ASC, [End_Time_Ms] ASC, [Historian_Quality_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarms_IX_KeyAlarmTypeEndTime]
    ON [dbo].[Alarms]([Key_Id] ASC, [Alarm_Type_Id] ASC, [End_Time] ASC);


GO
CREATE TRIGGER [dbo].[Alarms_History_Upd]
 ON  [dbo].[Alarms]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 403
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Alarm_History
 	  	   (Ack,Ack_By,Ack_Comment_ID,Ack_On,Ack_On_Ms,Action_Comment_Id,Action1,Action2,Action3,Action4,Alarm_Desc,Alarm_Id,Alarm_Type_Id,ATD_Id,ATSRD_Id,ATVRD_Id,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Cutoff,Data_Type_Id,Duration,End_Result,End_Time,End_Time_Ms,EngUnitLabel,Event_Reason_Tree_Data_Id,EventSubCategory_Id,Historian_Quality_Id,Key_Id,Max_Result,Min_Result,Alarms_Modified_On,Modified_On_Ms,OPCCondition_Id,OPCEventCategory_Id,OPCSeverity,OPCSubCondition_Id,Path_Id,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_Id,Source_PU_Id,Start_Result,Start_Time,Start_Time_Ms,SubType,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Ack,a.Ack_By,a.Ack_Comment_ID,a.Ack_On,a.Ack_On_Ms,a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Alarm_Desc,a.Alarm_Id,a.Alarm_Type_Id,a.ATD_Id,a.ATSRD_Id,a.ATVRD_Id,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Cutoff,a.Data_Type_Id,a.Duration,a.End_Result,a.End_Time,a.End_Time_Ms,a.EngUnitLabel,a.Event_Reason_Tree_Data_Id,a.EventSubCategory_Id,a.Historian_Quality_Id,a.Key_Id,a.Max_Result,a.Min_Result,a.Modified_On,a.Modified_On_Ms,a.OPCCondition_Id,a.OPCEventCategory_Id,a.OPCSeverity,a.OPCSubCondition_Id,a.Path_Id,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_Id,a.Source_PU_Id,a.Start_Result,a.Start_Time,a.Start_Time_Ms,a.SubType,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Alarms_Del
  ON dbo.Alarms
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id1 int,
 	 @Comment_Id2 int,
 	 @Comment_Id3 int,
 	 @Comment_Id4 int
DECLARE Alarms_Del_Cursor CURSOR
  FOR SELECT Research_Comment_Id, Action_Comment_Id, Cause_Comment_Id, Ack_Comment_ID FROM DELETED
  FOR READ ONLY
OPEN Alarms_Del_Cursor 
--
--
Fetch_Next_Alarm:
FETCH NEXT FROM Alarms_Del_Cursor INTO @Comment_Id1, @Comment_Id2, @Comment_Id3, @Comment_Id4
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
 	   GOTO Fetch_Next_Alarm
 	 END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Alarms_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Alarms_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Alarms_History_Del]
 ON  [dbo].[Alarms]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @ValidTrigger Bit
 Execute 	 spPDB_IsTriggerValid @ValidTrigger OUTPUT
 If @ValidTrigger = 0 Return
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 403
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Alarm_History
 	  	   (Ack,Ack_By,Ack_Comment_ID,Ack_On,Ack_On_Ms,Action_Comment_Id,Action1,Action2,Action3,Action4,Alarm_Desc,Alarm_Id,Alarm_Type_Id,ATD_Id,ATSRD_Id,ATVRD_Id,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Cutoff,Data_Type_Id,Duration,End_Result,End_Time,End_Time_Ms,EngUnitLabel,Event_Reason_Tree_Data_Id,EventSubCategory_Id,Historian_Quality_Id,Key_Id,Max_Result,Min_Result,Alarms_Modified_On,Modified_On_Ms,OPCCondition_Id,OPCEventCategory_Id,OPCSeverity,OPCSubCondition_Id,Path_Id,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_Id,Source_PU_Id,Start_Result,Start_Time,Start_Time_Ms,SubType,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Ack,a.Ack_By,a.Ack_Comment_ID,a.Ack_On,a.Ack_On_Ms,a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Alarm_Desc,a.Alarm_Id,a.Alarm_Type_Id,a.ATD_Id,a.ATSRD_Id,a.ATVRD_Id,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Cutoff,a.Data_Type_Id,a.Duration,a.End_Result,a.End_Time,a.End_Time_Ms,a.EngUnitLabel,a.Event_Reason_Tree_Data_Id,a.EventSubCategory_Id,a.Historian_Quality_Id,a.Key_Id,a.Max_Result,a.Min_Result,a.Modified_On,a.Modified_On_Ms,a.OPCCondition_Id,a.OPCEventCategory_Id,a.OPCSeverity,a.OPCSubCondition_Id,a.Path_Id,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_Id,a.Source_PU_Id,a.Start_Result,a.Start_Time,a.Start_Time_Ms,a.SubType,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Alarms_History_Ins]
 ON  [dbo].[Alarms]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 403
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Alarm_History
 	  	   (Ack,Ack_By,Ack_Comment_ID,Ack_On,Ack_On_Ms,Action_Comment_Id,Action1,Action2,Action3,Action4,Alarm_Desc,Alarm_Id,Alarm_Type_Id,ATD_Id,ATSRD_Id,ATVRD_Id,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Cutoff,Data_Type_Id,Duration,End_Result,End_Time,End_Time_Ms,EngUnitLabel,Event_Reason_Tree_Data_Id,EventSubCategory_Id,Historian_Quality_Id,Key_Id,Max_Result,Min_Result,Alarms_Modified_On,Modified_On_Ms,OPCCondition_Id,OPCEventCategory_Id,OPCSeverity,OPCSubCondition_Id,Path_Id,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_Id,Source_PU_Id,Start_Result,Start_Time,Start_Time_Ms,SubType,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Ack,a.Ack_By,a.Ack_Comment_ID,a.Ack_On,a.Ack_On_Ms,a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Alarm_Desc,a.Alarm_Id,a.Alarm_Type_Id,a.ATD_Id,a.ATSRD_Id,a.ATVRD_Id,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Cutoff,a.Data_Type_Id,a.Duration,a.End_Result,a.End_Time,a.End_Time_Ms,a.EngUnitLabel,a.Event_Reason_Tree_Data_Id,a.EventSubCategory_Id,a.Historian_Quality_Id,a.Key_Id,a.Max_Result,a.Min_Result,a.Modified_On,a.Modified_On_Ms,a.OPCCondition_Id,a.OPCEventCategory_Id,a.OPCSeverity,a.OPCSubCondition_Id,a.Path_Id,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_Id,a.Source_PU_Id,a.Start_Result,a.Start_Time,a.Start_Time_Ms,a.SubType,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
