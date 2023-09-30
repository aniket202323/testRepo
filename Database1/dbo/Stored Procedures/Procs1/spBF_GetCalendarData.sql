CREATE PROCEDURE dbo.spBF_GetCalendarData
 	 @SelectionType Int,
 	 @ItemId 	 Int = Null,
 	 @ItemId2 Int = Null,
 	 @TransType Int = Null,
 	 @StartTime DateTime = Null,
 	 @EndTime DateTime = Null
AS
IF @SelectionType = 1 --calGetAllProdUnits
BEGIN
  SELECT pu.pu_id,
 	  	 pu_desc = pu.pu_desc + '[' + pl.PL_Desc + ']' ,
 	  	 pu.PU_Desc_Global,
 	  	 pu.pl_id,
 	  	 treeTypeId = pu.Non_Productive_Reason_Tree 
 	 FROM Prod_Units pu 
 	 JOIN Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id
 	 WHERE pu.PL_Id > 0 and pl.Dept_Id > 0
 	 ORDER BY pu.pu_desc
END
ELSE IF @SelectionType = 2 -- spBF_calGetAllProdUnitsByLine (line)
BEGIN
 	 EXECUTE spBF_calGetAllProdUnitsByLine @ItemId,@ItemId2 	 
END
ELSE IF @SelectionType = 3 -- spBF_calGetCrewSchedule
BEGIN
 	 SELECT te.CS_Id,te.Comment_Id,te.Crew_Desc,te.End_Time,te.PU_Id,te.Shift_Desc,te.Start_Time,te.User_Id,
  	  	 machineName = u.PU_Desc , 
 	  	 shiftId = sc.Shift_Id,
 	  	 shiftName = sh.Name ,
 	  	 cs.Crew_Id , 
  	  	 crewName = cr.Name , 
 	  	 comments = co.Comment 
 	 FROM Crew_Schedule te
 	 LEFT JOIN Shifts_Crew_schedule_mapping sc on te.CS_Id = sc.Crew_Schedule_Id
 	 LEFT JOIN Shifts sh on sc.Shift_Id = sh.Id
 	 LEFT JOIN CrewSchedule_Crew_Mapping cs on te.CS_Id = cs.Crew_Schedule_Id
 	 LEFT JOIN Crews cr on cs.Crew_Id = cr.Id
 	 LEFT JOIN Comments co on te.Comment_Id = co.Comment_Id
 	 JOIN Prod_Units u on u.PU_Id = te.PU_Id
 	 WHERE te.cs_Id = @ItemId
END
ELSE IF @SelectionType = 4 -- spBF_calGetNonProdDetail
BEGIN
 	 SELECT te.NPDet_Id,te.Start_Time,te.End_Time,te.PU_Id,u.PU_Desc, 
 	  	 comment = c.Comment,
 	  	 te.Reason_Level1,
 	  	 r1.Event_Reason_Name_Local,  
 	  	 te.Reason_Level2,
 	  	 Reason_Name2 = r2.Event_Reason_Name_Local,
 	  	 te.Reason_Level3,
 	  	 Reason_Name3 = r3.Event_Reason_Name_Local,
 	  	 te.Reason_Level4,
 	  	 Reason_Name4 = r4.Event_Reason_Name_Local,
 	  	 treeNodeId = te.Event_Reason_Tree_Data_Id,
 	  	 treeId = u.Non_Productive_Reason_Tree, 
 	  	 te.NPT_Group_Id
 	 FROM NonProductive_Detail te
 	 LEFT JOIN Event_Reasons r1 on te.Reason_Level1 = r1.Event_Reason_Id 
 	 LEFT JOIN Event_Reasons r2 on te.Reason_Level2 = r2.Event_Reason_Id 
 	 LEFT JOIN Event_Reasons r3 on te.Reason_Level3 = r3.Event_Reason_Id 
 	 LEFT JOIN Event_Reasons r4 on te.Reason_Level4 = r4.Event_Reason_Id 
 	 LEFT JOIN comments c on c.Comment_Id = te.Comment_Id
 	 JOIN Prod_Units u on u.PU_Id = te.PU_Id
 	 WHERE te.NPDet_Id = @ItemId
END
ELSE IF @SelectionType = 5 -- spBF_calGetProdUnitsByLine
BEGIN
 	 EXECUTE spBF_calGetProdUnitsByLine @ItemId,@ItemId2
END
ELSE IF @SelectionType = 6 -- spBF_calGetReasonTree
BEGIN
 	 EXECUTE dbo.spBF_calGetReasonTree @ItemId
END
ELSE IF @SelectionType = 7 -- spBF_calGetCrews
BEGIN
 	   SELECT id,name,description FROM Crews WHERE isDeleted = 0 ORDER BY name
END
ELSE IF @SelectionType = 8 -- 
BEGIN
 	   EXECUTE spBF_calGetEventDetail @ItemId
END
ELSE IF @SelectionType = 9 -- spBF_calGetEventReasons
BEGIN
 	 SELECT Event_Reason_Id,
 	  	 Event_Reason_Name_Local,
 	  	 Event_Reason_Code,
 	  	 Comment_Required,
 	  	 Comment_Id 
 	 FROM Event_Reasons 
 	 ORDER BY Event_Reason_Name_Local
END
ELSE IF @SelectionType = 10  
BEGIN
 	 EXECUTE spBF_GetNPTData  @ItemId,@ItemId2,@TransType
END
ELSE IF @SelectionType = 11 -- 
BEGIN
 	 EXECUTE dbo.spEM_IEGetColumnData 'NonProductiveSchedule'
END
ELSE IF @SelectionType = 12 -- Export NPT
BEGIN
 	 SELECT PL_Desc,PU_Desc,Start_Time,End_Time,Tree_Name,
 	  	 Event_Reason_Name1 = e1.Event_Reason_Name,
 	  	 Event_Reason_Name2 = e2.Event_Reason_Name,
 	  	 Event_Reason_Name3 = e3.Event_Reason_Name,
 	  	 Event_Reason_Name4 = e4.Event_Reason_Name,
 	  	 Comment = Substring(c.Comment,1,255)
 	 FROM NonProductive_Detail npd
 	 JOIN Prod_Units pu On pu.PU_Id = npd.PU_Id
 	 JOIN Prod_Lines pl On pl.PL_Id = pu.PL_Id
 	 LEFT JOIN Event_Reason_Tree ert On ert.Tree_Name_Id = pu.Non_Productive_Reason_Tree
 	 LEFT JOIN Event_Reasons e1 On e1.Event_Reason_Id = npd.Reason_Level1
 	 LEFT JOIN Event_Reasons e2 On e2.Event_Reason_Id = npd.Reason_Level2
 	 LEFT JOIN Event_Reasons e3 On e3.Event_Reason_Id = npd.Reason_Level3
 	 LEFT JOIN Event_Reasons e4 On e4.Event_Reason_Id = npd.Reason_Level4
 	 LEFT JOIN Comments c on c.comment_Id = npd.comment_Id
WHERE  pu.PU_Id <> 0 and Master_Unit is NULL and Start_Time Between   @StartTime and  @EndTime
END
ELSE IF @SelectionType = 13 -- 
BEGIN
 	 SELECT TreeId = a.Non_Productive_Reason_Tree,b.Tree_Name   
 	  	 FROM prod_Units a 
 	  	 JOIN Event_Reason_Tree b on b.Tree_Name_Id = a.Non_Productive_Reason_Tree
 	  	 WHERE a.PU_Id = @ItemId
END
ELSE IF @SelectionType = 14 -- 
BEGIN
 	 SELECT pu.pu_id,
 	  	 pu_desc = pu.pu_desc + '[' + pl.PL_Desc +']',
 	  	 pu.PU_Desc_Global,
 	  	 pu.pl_id, 
 	  	 treeTypeId = pu.Non_Productive_Reason_Tree 
 	 FROM Prod_Units pu JOIN Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id
 	 WHERE pu.Non_Productive_Category = 7
 	 ORDER BY pu.pu_desc
END
ELSE IF @SelectionType = 15 -- 
BEGIN
 	 EXECUTE dbo.spBF_calGetShifts @ItemId
END
ELSE IF @SelectionType = 16 -- spBF_calGetUsersByCrew
BEGIN
 	 SELECT 	 u.user_id,
 	  	  	 u.userName, 
 	  	  	 u.SSOUserId,
 	  	  	 u.user_desc 
 	 FROM Users u 
 	 JOIN Crew_Users_Mapping c on (c.user_id = u.user_id) 
 	 WHERE c.Crew_Id = @ItemId 
END
ELSE IF @SelectionType = 17 -- spBF_calGetUsers
BEGIN
 	 SELECT user_id,
 	  	 userName, 
 	  	 SSOUserId,
 	  	 user_desc 
 	 FROM Users 
 	 WHERE system = 0 and Is_Role = 0 and Active = 1 
 	 ORDER BY userName
END
ELSE 
BEGIN
 	 SELECT Error = 'Error: selection type not found'
END
