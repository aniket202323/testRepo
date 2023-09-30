CREATE TABLE [dbo].[Waste_Event_Detail_History] (
    [Waste_Event_Detail_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PU_Id]                         INT           NULL,
    [TimeStamp]                     DATETIME      NULL,
    [Action_Comment_Id]             INT           NULL,
    [Action_Level1]                 INT           NULL,
    [Action_Level2]                 INT           NULL,
    [Action_Level3]                 INT           NULL,
    [Action_Level4]                 INT           NULL,
    [Amount]                        FLOAT (53)    NULL,
    [Cause_Comment_Id]              INT           NULL,
    [Dimension_A]                   FLOAT (53)    NULL,
    [Dimension_X]                   FLOAT (53)    NULL,
    [Dimension_Y]                   FLOAT (53)    NULL,
    [Dimension_Z]                   FLOAT (53)    NULL,
    [EC_Id]                         INT           NULL,
    [Entry_On]                      DATETIME      NULL,
    [Event_Id]                      INT           NULL,
    [Event_Reason_Tree_Data_Id]     INT           NULL,
    [Reason_Level1]                 INT           NULL,
    [Reason_Level2]                 INT           NULL,
    [Reason_Level3]                 INT           NULL,
    [Reason_Level4]                 INT           NULL,
    [Research_Close_Date]           DATETIME      NULL,
    [Research_Comment_Id]           INT           NULL,
    [Research_Open_Date]            DATETIME      NULL,
    [Research_Status_Id]            INT           NULL,
    [Research_User_Id]              INT           NULL,
    [Signature_Id]                  INT           NULL,
    [Source_PU_Id]                  INT           NULL,
    [Start_Coordinate_A]            FLOAT (53)    NULL,
    [Start_Coordinate_X]            FLOAT (53)    NULL,
    [Start_Coordinate_Y]            FLOAT (53)    NULL,
    [Start_Coordinate_Z]            FLOAT (53)    NULL,
    [User_General_1]                VARCHAR (255) NULL,
    [User_General_2]                VARCHAR (255) NULL,
    [User_General_3]                VARCHAR (255) NULL,
    [User_General_4]                VARCHAR (255) NULL,
    [User_General_5]                VARCHAR (255) NULL,
    [User_Id]                       INT           NULL,
    [WEFault_Id]                    INT           NULL,
    [WEMT_Id]                       INT           NULL,
    [WET_Id]                        INT           NULL,
    [Work_Order_Number]             VARCHAR (50)  NULL,
    [WED_Id]                        INT           NULL,
    [Modified_On]                   DATETIME      NULL,
    [DBTT_Id]                       TINYINT       NULL,
    [Column_Updated_BitMask]        VARCHAR (15)  NULL,
    CONSTRAINT [Waste_Event_Detail_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Waste_Event_Detail_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [WasteEventDetailHistory_IX_WEDIdModifiedOn]
    ON [dbo].[Waste_Event_Detail_History]([WED_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Waste_Event_Detail_History_UpdDel]
 ON  [dbo].[Waste_Event_Detail_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Waste_Event_Detail_History
 	 FROM Waste_Event_Detail_History a 
 	 JOIN  Deleted b on b.WED_Id = a.WED_Id
END
