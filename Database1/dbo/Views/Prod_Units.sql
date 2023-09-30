Create View dbo.Prod_Units
AS
select a.PU_Id,Chain_Start_Time,Comment_Id,Def_Event_Sheet_Id,Def_Measurement,
 	  	 Def_Production_Dest,Def_Production_Src,Default_Path_Id,Delete_Child_Events,Downtime_External_Category,
 	  	 Downtime_Percent_Alarm_Interval,Downtime_Percent_Alarm_Window,Downtime_Percent_Specification,Downtime_Scheduled_Category,Efficiency_Calculation_Type,
 	  	 Efficiency_Percent_Alarm_Interval,Efficiency_Percent_Alarm_Window,Efficiency_Percent_Specification,Efficiency_Variable,Equipment_Type,
 	  	 Extended_Info,External_Link,Group_Id,Master_Unit,Non_Productive_Category,
 	  	 Non_Productive_Reason_Tree,Performance_Downtime_Category,a.PL_Id,Production_Alarm_Interval,
 	  	 Production_Alarm_Window,Production_Event_Association,Production_Rate_Specification,Production_Rate_TimeUnits,Production_Type,
 	  	 Production_Variable,
 	  	 PU_Desc = Case When @@options&(512) !=(0) THEN Coalesce(S95Id,PU_Desc,PU_Desc_Global)
 	  	  	  	   ELSE  Coalesce(PU_Desc_Global,S95Id,PU_Desc)
 	  	  	  	   END,
 	  	 PU_Order,Sheet_Id,Tag,
 	  	 Timed_Event_Association,Unit_Type_Id,User_Defined1,User_Defined2,User_Defined3,
 	  	 Uses_Start_Time,Waste_Event_Association,Waste_Percent_Alarm_Interval,Waste_Percent_Alarm_Window,Waste_Percent_Specification,
 	  	 PU_Desc_Global,
 	  	 PU_Desc_Local = Coalesce(S95Id,PU_Desc,PU_Desc_Global)
FROM Prod_Units_Base a 
LEFT JOIN PAEquipment_Aspect_SOAEquipment b on a.PU_Id = b.PU_Id
LEFT JOIN  Equipment c on b.Origin1EquipmentId = c.EquipmentId
where  a.PU_Id != 0

GO
CREATE TRIGGER [dbo].[ProdUnitsViewIns]
 ON  [dbo].[Prod_Units]
  INSTEAD OF INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
 	 SET NOCOUNT ON
 	 DECLARE @PAId 	 Int
 	 INSERT INTO Prod_Units_Base(Chain_Start_Time,Comment_Id,Def_Event_Sheet_Id,Def_Measurement,Def_Production_Dest,
 	  	  	  	  	  	  	 Def_Production_Src,Default_Path_Id,Delete_Child_Events,Downtime_External_Category,Downtime_Percent_Alarm_Interval,
 	  	  	  	  	  	  	 Downtime_Percent_Alarm_Window,Downtime_Percent_Specification,Downtime_Scheduled_Category,Efficiency_Calculation_Type,Efficiency_Percent_Alarm_Interval,
 	  	  	  	  	  	  	 Efficiency_Percent_Alarm_Window,Efficiency_Percent_Specification,Efficiency_Variable,Equipment_Type,Extended_Info,
 	  	  	  	  	  	  	 External_Link,Group_Id,Master_Unit,Non_Productive_Category,Non_Productive_Reason_Tree,
 	  	  	  	  	  	  	 Performance_Downtime_Category,PL_Id,Production_Alarm_Interval,Production_Alarm_Window,Production_Event_Association,
 	  	  	  	  	  	  	 Production_Rate_Specification,Production_Rate_TimeUnits,Production_Type,Production_Variable,PU_Order,
 	  	  	  	  	  	  	 Sheet_Id,Tag,Timed_Event_Association,Unit_Type_Id,User_Defined1,User_Defined3,
 	  	  	  	  	  	  	 Uses_Start_Time,Waste_Event_Association,Waste_Percent_Alarm_Interval,Waste_Percent_Alarm_Window,Waste_Percent_Specification,
 	  	  	  	  	  	  	 PU_Desc)
  	  	 SELECT  Chain_Start_Time,Comment_Id,Def_Event_Sheet_Id,Def_Measurement,Def_Production_Dest,
 	  	  	  	  	  	  	 Def_Production_Src,Default_Path_Id,Coalesce(Delete_Child_Events,0),Downtime_External_Category,Downtime_Percent_Alarm_Interval,
 	  	  	  	  	  	  	 Downtime_Percent_Alarm_Window,Downtime_Percent_Specification,Downtime_Scheduled_Category,Efficiency_Calculation_Type,Efficiency_Percent_Alarm_Interval,
 	  	  	  	  	  	  	 Efficiency_Percent_Alarm_Window,Efficiency_Percent_Specification,Efficiency_Variable,Equipment_Type,Extended_Info,
 	  	  	  	  	  	  	 External_Link,Group_Id,Master_Unit,Non_Productive_Category,Non_Productive_Reason_Tree,
 	  	  	  	  	  	  	 Performance_Downtime_Category,PL_Id,Production_Alarm_Interval,Production_Alarm_Window,Coalesce(Production_Event_Association,0),
 	  	  	  	  	  	  	 Production_Rate_Specification,Production_Rate_TimeUnits,Production_Type,Production_Variable,PU_Order,
 	  	  	  	  	  	  	 Sheet_Id,Tag,Timed_Event_Association,Coalesce(Unit_Type_Id,1),User_Defined1,User_Defined3,
 	  	  	  	  	  	  	 Uses_Start_Time,Waste_Event_Association,Waste_Percent_Alarm_Interval,Waste_Percent_Alarm_Window,Waste_Percent_Specification,
 	  	  	  	  	  	  	 PU_Desc
  	    	    From Inserted 
  	 SELECT @PAId = SCOPE_IDENTITY()
 	 IF (@PAId > 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
 	   	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId) 	 VALUES(@PAId,43)
  	  	 
END
