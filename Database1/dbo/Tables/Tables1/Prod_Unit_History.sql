CREATE TABLE [dbo].[Prod_Unit_History] (
    [Prod_Unit_History_Id]              BIGINT                   IDENTITY (1, 1) NOT NULL,
    [PL_Id]                             INT                      NULL,
    [PU_Desc]                           [dbo].[Varchar_Desc]     NULL,
    [Delete_Child_Events]               BIT                      NULL,
    [Chain_Start_Time]                  TINYINT                  NULL,
    [Comment_Id]                        INT                      NULL,
    [Def_Event_Sheet_Id]                INT                      NULL,
    [Def_Measurement]                   INT                      NULL,
    [Def_Production_Dest]               INT                      NULL,
    [Def_Production_Src]                INT                      NULL,
    [Default_Path_Id]                   INT                      NULL,
    [Downtime_External_Category]        INT                      NULL,
    [Downtime_Percent_Alarm_Interval]   INT                      NULL,
    [Downtime_Percent_Alarm_Window]     INT                      NULL,
    [Downtime_Percent_Specification]    INT                      NULL,
    [Downtime_Scheduled_Category]       INT                      NULL,
    [Efficiency_Calculation_Type]       TINYINT                  NULL,
    [Efficiency_Percent_Alarm_Interval] INT                      NULL,
    [Efficiency_Percent_Alarm_Window]   INT                      NULL,
    [Efficiency_Percent_Specification]  INT                      NULL,
    [Efficiency_Variable]               INT                      NULL,
    [Equipment_Type]                    VARCHAR (50)             NULL,
    [Extended_Info]                     VARCHAR (255)            NULL,
    [External_Link]                     [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]                          INT                      NULL,
    [Master_Unit]                       INT                      NULL,
    [Non_Productive_Category]           INT                      NULL,
    [Non_Productive_Reason_Tree]        INT                      NULL,
    [Performance_Downtime_Category]     INT                      NULL,
    [Production_Alarm_Interval]         INT                      NULL,
    [Production_Alarm_Window]           INT                      NULL,
    [Production_Rate_Specification]     INT                      NULL,
    [Production_Rate_TimeUnits]         TINYINT                  NULL,
    [Production_Type]                   TINYINT                  NULL,
    [Production_Variable]               INT                      NULL,
    [PU_Order]                          TINYINT                  NULL,
    [Sheet_Id]                          INT                      NULL,
    [Tag]                               VARCHAR (50)             NULL,
    [Timed_Event_Association]           TINYINT                  NULL,
    [User_Defined1]                     VARCHAR (255)            NULL,
    [User_Defined2]                     VARCHAR (255)            NULL,
    [User_Defined3]                     VARCHAR (255)            NULL,
    [Uses_Start_Time]                   TINYINT                  NULL,
    [Waste_Event_Association]           TINYINT                  NULL,
    [Waste_Percent_Alarm_Interval]      INT                      NULL,
    [Waste_Percent_Alarm_Window]        INT                      NULL,
    [Waste_Percent_Specification]       INT                      NULL,
    [Production_Event_Association]      INT                      NULL,
    [Unit_Type_Id]                      INT                      NULL,
    [PU_Id]                             INT                      NULL,
    [Modified_On]                       DATETIME                 NULL,
    [DBTT_Id]                           TINYINT                  NULL,
    [Column_Updated_BitMask]            VARCHAR (15)             NULL,
    [Actual_Speed_Variable]             INT                      NULL,
    [Conversion_Factor_Spec]            INT                      NULL,
    [Target_Speed_Variable]             INT                      NULL,
    [Waste_Variable]                    INT                      NULL,
    [Total_Or_Good_Production]          INT                      NULL,
    CONSTRAINT [Prod_Unit_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Prod_Unit_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProdUnitHistory_IX_PUIdModifiedOn]
    ON [dbo].[Prod_Unit_History]([PU_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Prod_Unit_History_UpdDel]
 ON  [dbo].[Prod_Unit_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
