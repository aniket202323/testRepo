CREATE Procedure dbo.spEMUP_PutUnitProperties
@Tab tinyint,
@PU_Id int,
@Extended_Info nvarchar(255),
@External_Link nvarchar(255),
@Unit_Type_Id int,
@Equipment_Type nvarchar(50),
@Sheet_Id int,
@Production_Type tinyint,
@Production_Variable int,
@Production_Rate_TimeUnits tinyint,
@Production_Rate_Specification int,
@Production_Alarm_Interval int,
@Production_Alarm_Window int,
@Waste_Percent_Specification int,
@Waste_Percent_Alarm_Interval int,
@Waste_Percent_Alarm_Window int,
@Downtime_Scheduled_Category int,
@Downtime_External_Category int,
@Downtime_Percent_Specification int,
@Downtime_Percent_Alarm_Interval int,
@Downtime_Percent_Alarm_Window int,
@Efficiency_Calculation_Type tinyint,
@Efficiency_Variable int,
@Efficiency_Percent_Specification int,
@Efficiency_Percent_Alarm_Interval int,
@Efficiency_Percent_Alarm_Window int,
@Delete_Child_Events bit,
@User_Id int,
@Performance_Downtime_Category int,
@OldParm 	  	 Int, --- needed to put this in to match parms with admin.....
@Non_Productive_Category Int,
@Non_Productive_Reason_Tree Int,
@DefaultPathId 	 Int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMUP_PutUnitProperties',
             Isnull(Convert(nVarChar(10),@Tab),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@PU_Id),'Null') + ','  + 
             Isnull(Convert(nvarchar(255),@Extended_Info),'Null') + ','  + 
             Isnull(Convert(nvarchar(255),@External_Link),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Unit_Type_Id),'Null') + ','  + 
             Isnull(Convert(nvarchar(50),@Equipment_Type),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Sheet_Id),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Production_Type),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Production_Variable),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Production_Rate_TimeUnits),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Production_Rate_Specification),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Production_Alarm_Interval),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Production_Alarm_Window),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Waste_Percent_Specification),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Waste_Percent_Alarm_Interval),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Waste_Percent_Alarm_Window),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Downtime_Scheduled_Category),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Downtime_External_Category),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Downtime_Percent_Specification),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Downtime_Percent_Alarm_Interval),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Downtime_Percent_Alarm_Window),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Efficiency_Calculation_Type),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Efficiency_Variable),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Efficiency_Percent_Specification),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Efficiency_Percent_Alarm_Interval),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Efficiency_Percent_Alarm_Window),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Delete_Child_Events),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Performance_Downtime_Category),'Null') + ','  +
             Isnull(Convert(nVarChar(10),@DefaultPathId),'Null') + ','  +
             Isnull(Convert(nVarChar(10),@Non_Productive_Category),'Null') + ','  +
             Isnull(Convert(nVarChar(10),@Non_Productive_Reason_Tree),'Null') + ','  +
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @Tab = 1
  Update Prod_Units
    Set Extended_Info = @Extended_Info, External_Link = @External_Link, Unit_Type_Id = @Unit_Type_Id, 
        Equipment_Type = @Equipment_Type, Sheet_Id = @Sheet_Id, Delete_Child_Events = @Delete_Child_Events, Default_Path_Id = @DefaultPathId
  Where PU_Id = @PU_Id
Else If @Tab = 3
  Update Prod_Units
    Set Production_Type = @Production_Type, Production_Variable = @Production_Variable, 
        Production_Rate_TimeUnits = @Production_Rate_TimeUnits, Production_Rate_Specification = @Production_Rate_Specification, 
        Production_Alarm_Interval = @Production_Alarm_Interval, Production_Alarm_Window = @Production_Alarm_Window,
        Waste_Percent_Specification = @Waste_Percent_Specification, Waste_Percent_Alarm_Interval = @Waste_Percent_Alarm_Interval, 
        Waste_Percent_Alarm_Window = @Waste_Percent_Alarm_Window, Downtime_Scheduled_Category = @Downtime_Scheduled_Category, 
        Downtime_External_Category = @Downtime_External_Category, Downtime_Percent_Specification = @Downtime_Percent_Specification, 
        Downtime_Percent_Alarm_Interval = @Downtime_Percent_Alarm_Interval, Downtime_Percent_Alarm_Window = @Downtime_Percent_Alarm_Window,
        Efficiency_Calculation_Type = @Efficiency_Calculation_Type, Efficiency_Variable = @Efficiency_Variable, 
        Efficiency_Percent_Specification = @Efficiency_Percent_Specification, Efficiency_Percent_Alarm_Interval = @Efficiency_Percent_Alarm_Interval, 
        Efficiency_Percent_Alarm_Window = @Efficiency_Percent_Alarm_Window,
        Performance_Downtime_Category = @Performance_Downtime_Category,
 	  	 Non_Productive_Category = @Non_Productive_Category,
 	  	 Non_Productive_Reason_Tree = @Non_Productive_Reason_Tree        
  Where PU_Id = @PU_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
