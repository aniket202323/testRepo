CREATE TABLE [dbo].[Alarm_History] (
    [Alarm_History_Id]          BIGINT                    IDENTITY (1, 1) NOT NULL,
    [Alarm_Desc]                VARCHAR (1000)            NULL,
    [Alarm_Type_Id]             INT                       NULL,
    [Start_Time]                DATETIME                  NULL,
    [User_Id]                   INT                       NULL,
    [Ack]                       BIT                       NULL,
    [Ack_By]                    INT                       NULL,
    [Ack_Comment_ID]            INT                       NULL,
    [Ack_On]                    DATETIME                  NULL,
    [Action_Comment_Id]         INT                       NULL,
    [Action1]                   INT                       NULL,
    [Action2]                   INT                       NULL,
    [Action3]                   INT                       NULL,
    [Action4]                   INT                       NULL,
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
    [EngUnitLabel]              [dbo].[Varchar_Eng_Units] NULL,
    [Event_Reason_Tree_Data_Id] INT                       NULL,
    [EventSubCategory_Id]       INT                       NULL,
    [Historian_Quality_Id]      INT                       NULL,
    [Key_Id]                    INT                       NULL,
    [Max_Result]                [dbo].[Varchar_Value]     NULL,
    [Min_Result]                [dbo].[Varchar_Value]     NULL,
    [Alarms_Modified_On]        DATETIME                  NULL,
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
    [SubType]                   INT                       NULL,
    [Ack_On_Ms]                 SMALLINT                  NULL,
    [End_Time_Ms]               SMALLINT                  NULL,
    [Modified_On_Ms]            SMALLINT                  NULL,
    [Start_Time_Ms]             SMALLINT                  NULL,
    [Alarm_Id]                  INT                       NULL,
    [Modified_On]               DATETIME                  NULL,
    [DBTT_Id]                   TINYINT                   NULL,
    [Column_Updated_BitMask]    VARCHAR (15)              NULL,
    CONSTRAINT [Alarm_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Alarm_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [AlarmHistory_IX_AlarmsModifiedOnModifiedOnMs]
    ON [dbo].[Alarm_History]([Alarms_Modified_On] DESC, [Modified_On_Ms] DESC);


GO
CREATE NONCLUSTERED INDEX [AlarmHistory_IX_AlarmIdModifiedOn]
    ON [dbo].[Alarm_History]([Alarm_Id] ASC, [Modified_On] ASC);


GO
CREATE NONCLUSTERED INDEX [AlarmHistory_IX_SourceIdOPCConditionId]
    ON [dbo].[Alarm_History]([Source_Id] ASC, [OPCCondition_Id] ASC);


GO
CREATE TRIGGER [dbo].[Alarm_History_UpdDel]
 ON  [dbo].[Alarm_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Alarm_History
 	 FROM Alarm_History a 
 	 JOIN  Deleted b on b.Alarm_Id = a.Alarm_Id
END
