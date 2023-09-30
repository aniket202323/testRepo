CREATE TABLE [dbo].[Production_Plan_History] (
    [Production_Plan_History_Id]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [Entry_On]                     DATETIME      NULL,
    [Prod_Id]                      INT           NULL,
    [User_Id]                      INT           NULL,
    [PP_Type_Id]                   INT           NULL,
    [Actual_Bad_Items]             INT           NULL,
    [Actual_Bad_Quantity]          FLOAT (53)    NULL,
    [Actual_Down_Time]             FLOAT (53)    NULL,
    [Actual_End_Time]              DATETIME      NULL,
    [Actual_Good_Items]            INT           NULL,
    [Actual_Good_Quantity]         FLOAT (53)    NULL,
    [Actual_Repetitions]           INT           NULL,
    [Actual_Running_Time]          FLOAT (53)    NULL,
    [Actual_Start_Time]            DATETIME      NULL,
    [Adjusted_Quantity]            FLOAT (53)    NULL,
    [Alarm_Count]                  INT           NULL,
    [Block_Number]                 VARCHAR (50)  NULL,
    [BOM_Formulation_Id]           BIGINT        NULL,
    [Comment_Id]                   INT           NULL,
    [Extended_Info]                VARCHAR (255) NULL,
    [Forecast_End_Date]            DATETIME      NULL,
    [Forecast_Quantity]            FLOAT (53)    NULL,
    [Forecast_Start_Date]          DATETIME      NULL,
    [Implied_Sequence]             INT           NULL,
    [Late_Items]                   INT           NULL,
    [Parent_PP_Id]                 INT           NULL,
    [Path_Id]                      INT           NULL,
    [Predicted_Remaining_Duration] FLOAT (53)    NULL,
    [Predicted_Remaining_Quantity] FLOAT (53)    NULL,
    [Predicted_Total_Duration]     FLOAT (53)    NULL,
    [Process_Order]                VARCHAR (50)  NULL,
    [Production_Rate]              FLOAT (53)    NULL,
    [Source_PP_Id]                 INT           NULL,
    [User_General_1]               VARCHAR (255) NULL,
    [User_General_2]               VARCHAR (255) NULL,
    [User_General_3]               VARCHAR (255) NULL,
    [Control_Type]                 TINYINT       NULL,
    [PP_Status_Id]                 INT           NULL,
    [PP_Id]                        INT           NULL,
    [Modified_On]                  DATETIME      NULL,
    [DBTT_Id]                      TINYINT       NULL,
    [Column_Updated_BitMask]       VARCHAR (15)  NULL,
    [Implied_Sequence_Offset]      INT           NULL,
    CONSTRAINT [Production_Plan_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Production_Plan_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductionPlanHistory_IX_PPIdModifiedOn]
    ON [dbo].[Production_Plan_History]([PP_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Production_Plan_ERP_Ins]
 ON  [dbo].[Production_Plan_History]
  For INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 If (select count(*) from subscription_trigger Where Table_Id = 7) > 0
 	   Begin
 	  	 If (select count(*) from subscription_trigger Where Table_Id = 7 and key_id is null) > 0 	 
 	  	   Begin
 	  	  	 Insert Into ERP_Transactions (ActualId,DBTT_Id,Table_Id,Entry_On) 
 	  	  	  	 Select PP_Id,DBTT_Id,7,Modified_On
 	  	    	  	 From Inserted i
 	  	   End 	 
 	  	 Else
 	  	   Begin
 	  	  	 Insert Into ERP_Transactions (ActualId,DBTT_Id,Table_Id,Entry_On)
 	  	    	  	 Select PP_Id,DBTT_Id,7,Modified_On
 	  	    	  	 From Inserted i 
 	  	  	  	 Join Subscription_Trigger s on i.Path_Id = s.Key_Id
 	  	   End
 	   End

GO
CREATE TRIGGER [dbo].[Production_Plan_History_UpdDel]
 ON  [dbo].[Production_Plan_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
