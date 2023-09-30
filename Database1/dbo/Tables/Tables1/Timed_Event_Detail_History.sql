CREATE TABLE [dbo].[Timed_Event_Detail_History] (
    [Timed_Event_Detail_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [PU_Id]                         INT          NULL,
    [Start_Time]                    DATETIME     NULL,
    [Action_Comment_Id]             INT          NULL,
    [Action_Level1]                 INT          NULL,
    [Action_Level2]                 INT          NULL,
    [Action_Level3]                 INT          NULL,
    [Action_Level4]                 INT          NULL,
    [Amount]                        FLOAT (53)   NULL,
    [Cause_Comment_Id]              INT          NULL,
    [End_Time]                      DATETIME     NULL,
    [Event_Reason_Tree_Data_Id]     INT          NULL,
    [Initial_User_Id]               INT          NULL,
    [Reason_Level1]                 INT          NULL,
    [Reason_Level2]                 INT          NULL,
    [Reason_Level3]                 INT          NULL,
    [Reason_Level4]                 INT          NULL,
    [Research_Close_Date]           DATETIME     NULL,
    [Research_Comment_Id]           INT          NULL,
    [Research_Open_Date]            DATETIME     NULL,
    [Research_Status_Id]            INT          NULL,
    [Research_User_Id]              INT          NULL,
    [Signature_Id]                  INT          NULL,
    [Source_PU_Id]                  INT          NULL,
    [Summary_Action_Comment_Id]     INT          NULL,
    [Summary_Cause_Comment_Id]      INT          NULL,
    [Summary_Research_Comment_Id]   INT          NULL,
    [TEFault_Id]                    INT          NULL,
    [TEStatus_Id]                   INT          NULL,
    [Uptime]                        FLOAT (53)   NULL,
    [User_Id]                       INT          NULL,
    [Work_Order_Number]             VARCHAR (50) NULL,
    [TEDet_Id]                      INT          NULL,
    [Modified_On]                   DATETIME     NULL,
    [DBTT_Id]                       TINYINT      NULL,
    [Column_Updated_BitMask]        VARCHAR (15) NULL,
    [Duration]                      AS           (CONVERT([decimal](10,2),datediff(second,[Start_Time],[End_Time])/(60.0),0)),
    CONSTRAINT [Timed_Event_Detail_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Timed_Event_Detail_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [TimedEventDetailHistory_IX_TEDETIdModifiedOn]
    ON [dbo].[Timed_Event_Detail_History]([TEDet_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Timed_Event_Detail_History_UpdDel]
 ON  [dbo].[Timed_Event_Detail_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Timed_Event_Detail_History
 	 FROM Timed_Event_Detail_History a 
 	 JOIN  Deleted b on b.TEDet_Id = a.TEDet_Id
END
