CREATE TABLE [dbo].[Defect_Details_History] (
    [Defect_Details_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Entry_On]                  DATETIME     NULL,
    [User_Id]                   INT          NULL,
    [Action_Comment_Id]         INT          NULL,
    [Action1]                   INT          NULL,
    [Action2]                   INT          NULL,
    [Action3]                   INT          NULL,
    [Action4]                   INT          NULL,
    [Amount]                    FLOAT (53)   NULL,
    [Cause_Comment_Id]          INT          NULL,
    [Cause1]                    INT          NULL,
    [Cause2]                    INT          NULL,
    [Cause3]                    INT          NULL,
    [Cause4]                    INT          NULL,
    [Defect_Type_Id]            INT          NULL,
    [Dimension_A]               FLOAT (53)   NULL,
    [Dimension_X]               FLOAT (53)   NULL,
    [Dimension_Y]               FLOAT (53)   NULL,
    [Dimension_Z]               FLOAT (53)   NULL,
    [End_Position_Y]            FLOAT (53)   NULL,
    [End_Time]                  DATETIME     NULL,
    [Event_Id]                  INT          NULL,
    [Event_Subtype_Id]          INT          NULL,
    [PU_ID]                     INT          NULL,
    [Repeat]                    INT          NULL,
    [Research_Close_Date]       DATETIME     NULL,
    [Research_Comment_Id]       INT          NULL,
    [Research_Open_Date]        DATETIME     NULL,
    [Research_Status_Id]        INT          NULL,
    [Research_User_Id]          INT          NULL,
    [Severity]                  INT          NULL,
    [Source_PU_Id]              INT          NULL,
    [Start_Coordinate_A]        FLOAT (53)   NULL,
    [Start_Coordinate_X]        FLOAT (53)   NULL,
    [Start_Coordinate_Y]        FLOAT (53)   NULL,
    [Start_Coordinate_Z]        FLOAT (53)   NULL,
    [Start_Time]                DATETIME     NULL,
    [Defect_Detail_Id]          INT          NULL,
    [Modified_On]               DATETIME     NULL,
    [DBTT_Id]                   TINYINT      NULL,
    [Column_Updated_BitMask]    VARCHAR (15) NULL,
    CONSTRAINT [Defect_Details_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Defect_Details_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [DefectDetailsHistory_IX_DefectDetailIdEntryOnModifiedOn]
    ON [dbo].[Defect_Details_History]([Defect_Detail_Id] ASC, [Entry_On] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Defect_Details_History_UpdDel]
 ON  [dbo].[Defect_Details_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
