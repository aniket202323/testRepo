CREATE TABLE [dbo].[User_Defined_Event_History] (
    [User_Defined_Event_History_Id]   BIGINT                    IDENTITY (1, 1) NOT NULL,
    [Event_Subtype_Id]                INT                       NULL,
    [UDE_Desc]                        VARCHAR (1000)            NULL,
    [Ack]                             BIT                       NULL,
    [Ack_By]                          INT                       NULL,
    [Ack_On]                          DATETIME                  NULL,
    [Action_Comment_Id]               INT                       NULL,
    [Action1]                         INT                       NULL,
    [Action2]                         INT                       NULL,
    [Action3]                         INT                       NULL,
    [Action4]                         INT                       NULL,
    [Cause_Comment_Id]                INT                       NULL,
    [Cause1]                          INT                       NULL,
    [Cause2]                          INT                       NULL,
    [Cause3]                          INT                       NULL,
    [Cause4]                          INT                       NULL,
    [Comment_Id]                      INT                       NULL,
    [Duration]                        INT                       NULL,
    [End_Time]                        DATETIME                  NULL,
    [Event_Id]                        INT                       NULL,
    [Event_Reason_Tree_Data_Id]       INT                       NULL,
    [EventSubCategory_Id]             INT                       NULL,
    [Historian_Quality_Id]            INT                       NULL,
    [User_Defined_Events_Modified_On] DATETIME                  NULL,
    [NewEngUnitLabel]                 [dbo].[Varchar_Eng_Units] NULL,
    [NewValue]                        [dbo].[Varchar_Value]     NULL,
    [OldEngUnitLabel]                 [dbo].[Varchar_Eng_Units] NULL,
    [OldValue]                        [dbo].[Varchar_Value]     NULL,
    [OPCEventCategory_Id]             INT                       NULL,
    [OPCSeverity]                     INT                       NULL,
    [Parent_UDE_Id]                   INT                       NULL,
    [PU_Id]                           INT                       NULL,
    [Research_Close_Date]             DATETIME                  NULL,
    [Research_Comment_Id]             INT                       NULL,
    [Research_Open_Date]              DATETIME                  NULL,
    [Research_Status_Id]              INT                       NULL,
    [Research_User_Id]                INT                       NULL,
    [Signature_Id]                    INT                       NULL,
    [Source_Id]                       INT                       NULL,
    [Start_Time]                      DATETIME                  NULL,
    [User_Id]                         INT                       NULL,
    [Ack_On_Ms]                       SMALLINT                  NULL,
    [End_Time_Ms]                     SMALLINT                  NULL,
    [Modified_On_Ms]                  SMALLINT                  NULL,
    [Start_Time_Ms]                   SMALLINT                  NULL,
    [UDE_Id]                          INT                       NULL,
    [Modified_On]                     DATETIME                  NULL,
    [DBTT_Id]                         TINYINT                   NULL,
    [Column_Updated_BitMask]          VARCHAR (15)              NULL,
    [Conformance]                     TINYINT                   NULL,
    [Event_Status]                    INT                       NULL,
    [Testing_Prct_Complete]           TINYINT                   NULL,
    [Testing_Status]                  INT                       NULL,
    [Friendly_Desc]                   VARCHAR (1000)            NULL,
    CONSTRAINT [User_Defined_Event_History_PK_Id] PRIMARY KEY NONCLUSTERED ([User_Defined_Event_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [UserDefinedEventHistory_IX_UDEIdModifiedOn]
    ON [dbo].[User_Defined_Event_History]([UDE_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[User_Defined_Event_History_UpdDel]
 ON  [dbo].[User_Defined_Event_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE User_Defined_Event_History
 	 FROM User_Defined_Event_History a 
 	 JOIN  Deleted b on b.UDE_Id = a.UDE_Id
END
