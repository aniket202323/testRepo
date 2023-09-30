Create Procedure dbo.spSDK_QueryReasonTreeAssignments
 	 @LineMask  	  	  	 nvarchar(50) = NULL,
 	 @MasterUnitMask 	 nvarchar(50) = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) = NULL,
 	 @EventType 	  	  	 INT = NULL
AS
SELECT 	 @LineMask  	  	  	 = REPLACE(REPLACE(REPLACE(COALESCE(@LineMask, '*'), '*', '%'), '?', '_'), '[', '[[]')
SELECT 	 @UnitMask  	  	  	 = REPLACE(REPLACE(REPLACE(COALESCE(@UnitMask, '*'), '*', '%'), '?', '_'), '[', '[[]')
SELECT 	 @MasterUnitMask 	 = REPLACE(REPLACE(REPLACE(COALESCE(@MasterUnitMask, '*'), '*', '%'), '?', '_'), '[', '[[]')
SELECT 	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 MasterUnit = COALESCE(mpu.PU_Desc, pu.PU_Desc), 
 	  	  	 EventType = Event_Type, 
 	  	  	 CauseTree = ert.Tree_Name, 
 	  	  	 ActionEnabled = pe.Action_Reason_Enabled, 
 	  	  	 ActionTree = art.Tree_Name, 
 	  	  	 ResearchEnabled = pe.Research_Enabled
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units pu 	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	 LEFT JOIN 	 Prod_Units mpu 	  	  	  	 ON 	  	 pu.Master_Unit = mpu.PU_Id
 	 JOIN 	  	  	 Prod_Events pe 	  	  	  	 ON 	  	 pu.PU_Id = pe.PU_Id
 	 LEFT JOIN 	 Event_Types et 	  	  	  	 ON 	  	 pe.Event_Type = et.ET_Id
 	 LEFT JOIN 	 Event_Reason_Tree ert 	 ON 	  	 pe.Name_Id = ert.Tree_Name_Id
 	 LEFT JOIN 	 Event_Reason_Tree art 	 ON 	  	 pe.Action_Tree_Id = art.Tree_Name_Id
 	 WHERE 	 COALESCE(mpu.PU_Desc, pu.PU_Desc) LIKE @MasterUnitMask
 	 AND 	 CASE
 	  	  	  	 WHEN @EventType IS NULL THEN 1
 	  	  	  	 WHEN @EventType IS NOT NULL AND pe.Event_Type = @EventType THEN 1
 	  	  	  	 ELSE 0
 	  	  	 END = 1
 	 ORDER BY pl.PL_Desc ASC, pu.PU_Order ASC, MasterUnit ASC
