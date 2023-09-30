CREATE TABLE [dbo].[Prod_Units_Base] (
    [PU_Id]                             INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Chain_Start_Time]                  TINYINT                  NULL,
    [Comment_Id]                        INT                      NULL,
    [Def_Event_Sheet_Id]                INT                      NULL,
    [Def_Measurement]                   INT                      NULL,
    [Def_Production_Dest]               INT                      NULL,
    [Def_Production_Src]                INT                      NULL,
    [Default_Path_Id]                   INT                      NULL,
    [Delete_Child_Events]               BIT                      CONSTRAINT [ProdUnits_DF_DeleteChildEvents] DEFAULT ((0)) NOT NULL,
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
    [PL_Id]                             INT                      NOT NULL,
    [Production_Alarm_Interval]         INT                      NULL,
    [Production_Alarm_Window]           INT                      NULL,
    [Production_Event_Association]      INT                      CONSTRAINT [ProdUnits_DF_ProdEventAssoc] DEFAULT ((0)) NULL,
    [Production_Rate_Specification]     INT                      NULL,
    [Production_Rate_TimeUnits]         TINYINT                  NULL,
    [Production_Type]                   TINYINT                  NULL,
    [Production_Variable]               INT                      NULL,
    [PU_Desc]                           [dbo].[Varchar_Desc]     NOT NULL,
    [PU_Desc_Global]                    VARCHAR (50)             NULL,
    [PU_Order]                          TINYINT                  NULL,
    [Sheet_Id]                          INT                      NULL,
    [Tag]                               VARCHAR (50)             NULL,
    [Timed_Event_Association]           TINYINT                  NULL,
    [Unit_Type_Id]                      INT                      CONSTRAINT [ProdUnits_DF_UnitTypeId] DEFAULT ((1)) NULL,
    [User_Defined1]                     VARCHAR (255)            NULL,
    [User_Defined2]                     VARCHAR (255)            NULL,
    [User_Defined3]                     VARCHAR (255)            NULL,
    [Uses_Start_Time]                   TINYINT                  NULL,
    [Waste_Event_Association]           TINYINT                  NULL,
    [Waste_Percent_Alarm_Interval]      INT                      NULL,
    [Waste_Percent_Alarm_Window]        INT                      NULL,
    [Waste_Percent_Specification]       INT                      NULL,
    [Actual_Speed_Variable]             INT                      NULL,
    [Conversion_Factor_Spec]            INT                      NULL,
    [Target_Speed_Variable]             INT                      NULL,
    [Total_Or_Good_Production]          INT                      CONSTRAINT [Prod_Units_Base_DF_Total_Or_Good_Production] DEFAULT ((1)) NULL,
    [Waste_Variable]                    INT                      NULL,
    CONSTRAINT [PK___2__12] PRIMARY KEY CLUSTERED ([PU_Id] ASC),
    CONSTRAINT [Prod_Units_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [Prod_Units_FK_PLId] FOREIGN KEY ([PL_Id]) REFERENCES [dbo].[Prod_Lines_Base] ([PL_Id]),
    CONSTRAINT [ProdUnits_FK_PathId] FOREIGN KEY ([Default_Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [ProdUnits_FK_PEAId] FOREIGN KEY ([Production_Event_Association]) REFERENCES [dbo].[Production_Event_Association] ([PEA_Id]),
    CONSTRAINT [ProdUnitsDECat_FK_Specifications] FOREIGN KEY ([Downtime_External_Category]) REFERENCES [dbo].[Event_Reason_Catagories] ([ERC_Id]),
    CONSTRAINT [ProdUnitsDSCat_FK_ReasonCategory] FOREIGN KEY ([Downtime_Scheduled_Category]) REFERENCES [dbo].[Event_Reason_Catagories] ([ERC_Id]),
    CONSTRAINT [ProdUnitsDTSpec_FK_Specifications] FOREIGN KEY ([Downtime_Percent_Specification]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [ProdUnitsEffVariable_FK_Variables] FOREIGN KEY ([Efficiency_Variable]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [ProdUnitsEFSpec_FK_Specifications] FOREIGN KEY ([Efficiency_Percent_Specification]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [ProdUnitsNPCat_FK_ReasonCategory] FOREIGN KEY ([Non_Productive_Category]) REFERENCES [dbo].[Event_Reason_Catagories] ([ERC_Id]),
    CONSTRAINT [ProdUnitsNPReasonTree_FK_ReasonCategory] FOREIGN KEY ([Non_Productive_Reason_Tree]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [ProdUnitsProdVariable_FK_Variables] FOREIGN KEY ([Production_Variable]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [ProdUnitsPRSpec_FK_Specifications] FOREIGN KEY ([Production_Rate_Specification]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [ProdUnitsSheets_FK_Sheets] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [ProdUnitsUnitType_FK_Unit_Types] FOREIGN KEY ([Unit_Type_Id]) REFERENCES [dbo].[Unit_Types] ([Unit_Type_Id]),
    CONSTRAINT [ProdUnitsWPSpec_FK_ReasonCategory] FOREIGN KEY ([Waste_Percent_Specification]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [Prod_Units_UC_PLIdPUDesc] UNIQUE NONCLUSTERED ([PL_Id] ASC, [PU_Desc] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ProdUnit_IDX_EquipmentType]
    ON [dbo].[Prod_Units_Base]([Equipment_Type] ASC);


GO
CREATE NONCLUSTERED INDEX [Prod_Units_IDX_MasterUnit]
    ON [dbo].[Prod_Units_Base]([Master_Unit] ASC);


GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_Prod_Units_Base_Sync]
  	  ON [dbo].[Prod_Units_Base]
  	  FOR INSERT,  DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;

GO
CREATE TRIGGER [dbo].[Prod_Units_History_Del]
 ON  [dbo].[Prod_Units_Base]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 422
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Prod_Unit_History
 	  	   (Actual_Speed_Variable,Chain_Start_Time,Comment_Id,Conversion_Factor_Spec,Def_Event_Sheet_Id,Def_Measurement,Def_Production_Dest,Def_Production_Src,Default_Path_Id,Delete_Child_Events,Downtime_External_Category,Downtime_Percent_Alarm_Interval,Downtime_Percent_Alarm_Window,Downtime_Percent_Specification,Downtime_Scheduled_Category,Efficiency_Calculation_Type,Efficiency_Percent_Alarm_Interval,Efficiency_Percent_Alarm_Window,Efficiency_Percent_Specification,Efficiency_Variable,Equipment_Type,Extended_Info,External_Link,Group_Id,Master_Unit,Non_Productive_Category,Non_Productive_Reason_Tree,Performance_Downtime_Category,PL_Id,Production_Alarm_Interval,Production_Alarm_Window,Production_Event_Association,Production_Rate_Specification,Production_Rate_TimeUnits,Production_Type,Production_Variable,PU_Desc,PU_Id,PU_Order,Sheet_Id,Tag,Target_Speed_Variable,Timed_Event_Association,Total_Or_Good_Production,Unit_Type_Id,User_Defined1,User_Defined2,User_Defined3,Uses_Start_Time,Waste_Event_Association,Waste_Percent_Alarm_Interval,Waste_Percent_Alarm_Window,Waste_Percent_Specification,Waste_Variable,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Actual_Speed_Variable,a.Chain_Start_Time,a.Comment_Id,a.Conversion_Factor_Spec,a.Def_Event_Sheet_Id,a.Def_Measurement,a.Def_Production_Dest,a.Def_Production_Src,a.Default_Path_Id,a.Delete_Child_Events,a.Downtime_External_Category,a.Downtime_Percent_Alarm_Interval,a.Downtime_Percent_Alarm_Window,a.Downtime_Percent_Specification,a.Downtime_Scheduled_Category,a.Efficiency_Calculation_Type,a.Efficiency_Percent_Alarm_Interval,a.Efficiency_Percent_Alarm_Window,a.Efficiency_Percent_Specification,a.Efficiency_Variable,a.Equipment_Type,a.Extended_Info,a.External_Link,a.Group_Id,a.Master_Unit,a.Non_Productive_Category,a.Non_Productive_Reason_Tree,a.Performance_Downtime_Category,a.PL_Id,a.Production_Alarm_Interval,a.Production_Alarm_Window,a.Production_Event_Association,a.Production_Rate_Specification,a.Production_Rate_TimeUnits,a.Production_Type,a.Production_Variable,a.PU_Desc,a.PU_Id,a.PU_Order,a.Sheet_Id,a.Tag,a.Target_Speed_Variable,a.Timed_Event_Association,a.Total_Or_Good_Production,a.Unit_Type_Id,a.User_Defined1,a.User_Defined2,a.User_Defined3,a.Uses_Start_Time,a.Waste_Event_Association,a.Waste_Percent_Alarm_Interval,a.Waste_Percent_Alarm_Window,a.Waste_Percent_Specification,a.Waste_Variable,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Prod_Units_Ins 
  ON dbo.Prod_Units_Base
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
--
-- Insert a initial production start record for each new production unit.
--
INSERT INTO Production_Starts (PU_Id,Prod_Id,Start_Time,End_Time,Confirmed)
  SELECT i.PU_Id,
         Prod_Id = 1,
         Start_Time = 'Jan 1, 1971 00:00',
         End_Time = NULL,
         Confirmed = 0
    FROM INSERTED i
INSERT INTO PrdExec_Status (PU_Id,Step,Valid_Status,Is_Default_Status)
  SELECT i.PU_Id,1,Null,Null
    FROM INSERTED i
-- Default Statuses
Declare @StatusId Int
Declare Status_Cursor Cursor For Select ProdStatus_Id From Production_Status
 	 Where ProdStatus_Id In (5,8,9,10,11,12)
Open Status_Cursor
StatusCursorLoop:
Fetch Next From Status_Cursor Into @StatusId
If @@Fetch_Status = 0
 Begin
 	 INSERT INTO PrdExec_Status (PU_Id,Step,Valid_Status,Is_Default_Status)
   	   SELECT i.PU_Id,1,@StatusId,Case When @StatusId = 5 then 1 Else 0 End
     	 FROM INSERTED i
 	 Declare @StatusId1 Int
 	 Declare Status_Cursor1 Cursor For Select ProdStatus_Id From Production_Status
 	  	 Where ProdStatus_Id In (5,8,9,10,11,12) and ProdStatus_Id <> @StatusId
 	 Open Status_Cursor1
 	 StatusCursorLoop1:
 	 Fetch Next From Status_Cursor1 Into @StatusId1
 	 If @@Fetch_Status = 0
 	  Begin
 	  	 INSERT INTO PrdExec_Trans (PU_Id,From_ProdStatus_Id,To_ProdStatus_Id)
   	  	   SELECT i.PU_Id,@StatusId, @StatusId1
     	  	 FROM INSERTED i
 	  	 Goto StatusCursorLoop1
 	  End
 	 Close Status_Cursor1
 	 Deallocate Status_Cursor1
 	 Goto StatusCursorLoop
 End
Close Status_Cursor
Deallocate Status_Cursor

GO
CREATE TRIGGER [dbo].[Prod_Units_History_Ins]
 ON  [dbo].[Prod_Units_Base]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 422
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Prod_Unit_History
 	  	   (Actual_Speed_Variable,Chain_Start_Time,Comment_Id,Conversion_Factor_Spec,Def_Event_Sheet_Id,Def_Measurement,Def_Production_Dest,Def_Production_Src,Default_Path_Id,Delete_Child_Events,Downtime_External_Category,Downtime_Percent_Alarm_Interval,Downtime_Percent_Alarm_Window,Downtime_Percent_Specification,Downtime_Scheduled_Category,Efficiency_Calculation_Type,Efficiency_Percent_Alarm_Interval,Efficiency_Percent_Alarm_Window,Efficiency_Percent_Specification,Efficiency_Variable,Equipment_Type,Extended_Info,External_Link,Group_Id,Master_Unit,Non_Productive_Category,Non_Productive_Reason_Tree,Performance_Downtime_Category,PL_Id,Production_Alarm_Interval,Production_Alarm_Window,Production_Event_Association,Production_Rate_Specification,Production_Rate_TimeUnits,Production_Type,Production_Variable,PU_Desc,PU_Id,PU_Order,Sheet_Id,Tag,Target_Speed_Variable,Timed_Event_Association,Total_Or_Good_Production,Unit_Type_Id,User_Defined1,User_Defined2,User_Defined3,Uses_Start_Time,Waste_Event_Association,Waste_Percent_Alarm_Interval,Waste_Percent_Alarm_Window,Waste_Percent_Specification,Waste_Variable,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Actual_Speed_Variable,a.Chain_Start_Time,a.Comment_Id,a.Conversion_Factor_Spec,a.Def_Event_Sheet_Id,a.Def_Measurement,a.Def_Production_Dest,a.Def_Production_Src,a.Default_Path_Id,a.Delete_Child_Events,a.Downtime_External_Category,a.Downtime_Percent_Alarm_Interval,a.Downtime_Percent_Alarm_Window,a.Downtime_Percent_Specification,a.Downtime_Scheduled_Category,a.Efficiency_Calculation_Type,a.Efficiency_Percent_Alarm_Interval,a.Efficiency_Percent_Alarm_Window,a.Efficiency_Percent_Specification,a.Efficiency_Variable,a.Equipment_Type,a.Extended_Info,a.External_Link,a.Group_Id,a.Master_Unit,a.Non_Productive_Category,a.Non_Productive_Reason_Tree,a.Performance_Downtime_Category,a.PL_Id,a.Production_Alarm_Interval,a.Production_Alarm_Window,a.Production_Event_Association,a.Production_Rate_Specification,a.Production_Rate_TimeUnits,a.Production_Type,a.Production_Variable,a.PU_Desc,a.PU_Id,a.PU_Order,a.Sheet_Id,a.Tag,a.Target_Speed_Variable,a.Timed_Event_Association,a.Total_Or_Good_Production,a.Unit_Type_Id,a.User_Defined1,a.User_Defined2,a.User_Defined3,a.Uses_Start_Time,a.Waste_Event_Association,a.Waste_Percent_Alarm_Interval,a.Waste_Percent_Alarm_Window,a.Waste_Percent_Specification,a.Waste_Variable,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Prod_Units_History_Upd]
 ON  [dbo].[Prod_Units_Base]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 422
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Prod_Unit_History
 	  	   (Actual_Speed_Variable,Chain_Start_Time,Comment_Id,Conversion_Factor_Spec,Def_Event_Sheet_Id,Def_Measurement,Def_Production_Dest,Def_Production_Src,Default_Path_Id,Delete_Child_Events,Downtime_External_Category,Downtime_Percent_Alarm_Interval,Downtime_Percent_Alarm_Window,Downtime_Percent_Specification,Downtime_Scheduled_Category,Efficiency_Calculation_Type,Efficiency_Percent_Alarm_Interval,Efficiency_Percent_Alarm_Window,Efficiency_Percent_Specification,Efficiency_Variable,Equipment_Type,Extended_Info,External_Link,Group_Id,Master_Unit,Non_Productive_Category,Non_Productive_Reason_Tree,Performance_Downtime_Category,PL_Id,Production_Alarm_Interval,Production_Alarm_Window,Production_Event_Association,Production_Rate_Specification,Production_Rate_TimeUnits,Production_Type,Production_Variable,PU_Desc,PU_Id,PU_Order,Sheet_Id,Tag,Target_Speed_Variable,Timed_Event_Association,Total_Or_Good_Production,Unit_Type_Id,User_Defined1,User_Defined2,User_Defined3,Uses_Start_Time,Waste_Event_Association,Waste_Percent_Alarm_Interval,Waste_Percent_Alarm_Window,Waste_Percent_Specification,Waste_Variable,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Actual_Speed_Variable,a.Chain_Start_Time,a.Comment_Id,a.Conversion_Factor_Spec,a.Def_Event_Sheet_Id,a.Def_Measurement,a.Def_Production_Dest,a.Def_Production_Src,a.Default_Path_Id,a.Delete_Child_Events,a.Downtime_External_Category,a.Downtime_Percent_Alarm_Interval,a.Downtime_Percent_Alarm_Window,a.Downtime_Percent_Specification,a.Downtime_Scheduled_Category,a.Efficiency_Calculation_Type,a.Efficiency_Percent_Alarm_Interval,a.Efficiency_Percent_Alarm_Window,a.Efficiency_Percent_Specification,a.Efficiency_Variable,a.Equipment_Type,a.Extended_Info,a.External_Link,a.Group_Id,a.Master_Unit,a.Non_Productive_Category,a.Non_Productive_Reason_Tree,a.Performance_Downtime_Category,a.PL_Id,a.Production_Alarm_Interval,a.Production_Alarm_Window,a.Production_Event_Association,a.Production_Rate_Specification,a.Production_Rate_TimeUnits,a.Production_Type,a.Production_Variable,a.PU_Desc,a.PU_Id,a.PU_Order,a.Sheet_Id,a.Tag,a.Target_Speed_Variable,a.Timed_Event_Association,a.Total_Or_Good_Production,a.Unit_Type_Id,a.User_Defined1,a.User_Defined2,a.User_Defined3,a.Uses_Start_Time,a.Waste_Event_Association,a.Waste_Percent_Alarm_Interval,a.Waste_Percent_Alarm_Window,a.Waste_Percent_Specification,a.Waste_Variable,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Prod_Units_TableFieldValue_Del]
 ON  [dbo].[Prod_Units_Base]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PU_Id
 WHERE tfv.TableId = 43

GO
Create  TRIGGER dbo.ProdUnits_Reload_InsUpdDel
 	 ON dbo.Prod_Units_Base
 	 FOR INSERT, UPDATE, DELETE
 	 AS
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (17)

GO
CREATE TRIGGER dbo.Prod_Units_Del 
  ON dbo.Prod_Units_Base 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Prod_Units_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Prod_Units_Del_Cursor 
--
--
Fetch_Next_Prod_Units_Del:
FETCH NEXT FROM Prod_Units_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_Prod_Units_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Prod_Units_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Prod_Units_Del_Cursor 
