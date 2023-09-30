CREATE TABLE [dbo].[Production_Setup_History] (
    [Production_Setup_History_Id]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [PP_Id]                        INT           NULL,
    [PP_Status_Id]                 INT           NULL,
    [Actual_Bad_Items]             INT           NULL,
    [Actual_Bad_Quantity]          FLOAT (53)    NULL,
    [Actual_Down_Time]             FLOAT (53)    NULL,
    [Actual_End_Time]              DATETIME      NULL,
    [Actual_Good_Items]            INT           NULL,
    [Actual_Good_Quantity]         FLOAT (53)    NULL,
    [Actual_Repetitions]           INT           NULL,
    [Actual_Running_Time]          FLOAT (53)    NULL,
    [Actual_Start_Time]            DATETIME      NULL,
    [Alarm_Count]                  INT           NULL,
    [Base_Dimension_A]             REAL          NULL,
    [Base_Dimension_X]             REAL          NULL,
    [Base_Dimension_Y]             REAL          NULL,
    [Base_Dimension_Z]             REAL          NULL,
    [Base_General_1]               REAL          NULL,
    [Base_General_2]               REAL          NULL,
    [Base_General_3]               REAL          NULL,
    [Base_General_4]               REAL          NULL,
    [Comment_Id]                   INT           NULL,
    [Entry_On]                     DATETIME      NULL,
    [Extended_Info]                VARCHAR (255) NULL,
    [Forecast_Quantity]            FLOAT (53)    NULL,
    [Implied_Sequence]             INT           NULL,
    [Late_Items]                   INT           NULL,
    [Parent_PP_Setup_Id]           INT           NULL,
    [Pattern_Code]                 VARCHAR (25)  NULL,
    [Pattern_Repititions]          INT           NULL,
    [Predicted_Remaining_Duration] FLOAT (53)    NULL,
    [Predicted_Remaining_Quantity] FLOAT (53)    NULL,
    [Predicted_Total_Duration]     FLOAT (53)    NULL,
    [Shrinkage]                    REAL          NULL,
    [User_General_1]               VARCHAR (255) NULL,
    [User_General_2]               VARCHAR (255) NULL,
    [User_General_3]               VARCHAR (255) NULL,
    [User_Id]                      INT           NULL,
    [PP_Setup_Id]                  INT           NULL,
    [Modified_On]                  DATETIME      NULL,
    [DBTT_Id]                      TINYINT       NULL,
    [Column_Updated_BitMask]       VARCHAR (15)  NULL,
    CONSTRAINT [Production_Setup_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Production_Setup_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductionSetupHistory_IX_PPSetupIdModifiedOn]
    ON [dbo].[Production_Setup_History]([PP_Setup_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Production_Setup_History_UpdDel]
 ON  [dbo].[Production_Setup_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
