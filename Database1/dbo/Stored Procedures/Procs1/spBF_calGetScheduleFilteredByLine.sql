-- =============================================
-- Author:  	    	  <502406286, Alfredo Scotto>
-- Create date: <Create Date,,>
-- Description:  	  <Description,,>
-- =============================================
CREATE PROCEDURE dbo.spBF_calGetScheduleFilteredByLine
 	 @lineId 	  	 Int,
 	 @isLineId 	 Int,
 	 @Start_Time datetime,
 	 @End_Time 	 datetime,
 	 @crewOn 	  	 Int,
 	 @operationOn Int,
 	 @offTimeOn 	 Int,
 	 @downTime 	 Int,
 	 @nonProdTime Int,
 	 @reasonId 	 Int
AS
SET NOCOUNT ON
DECLARE @Results Table(Id nvarchar(100),schedType nvarchar(100),content nvarchar(max),
 	  	  	 machine nvarchar(max),shift_name nvarchar(max),start_time DateTime,end_time DateTime,Line nvarchar(max))
DECLARE @DepartmentTimeZone nvarchar(255) 	  	 
DECLARE @Units Table(id Int Identity(1,1),PUId Int)
IF @isLineId = 1
 	 INSERT INTO @Units(PUId) 
 	  	 SELECT PUId FROM dbo.fnBF_CreateUnitList(@lineId,'')
ELSE
 	 INSERT INTO @Units(PUId) VALUES(@lineId)
SELECT @End_Time = Coalesce(@End_Time,@Start_Time)
IF DateDiff(hour,@Start_Time,@End_Time) < 20 -- always expect  day or >
BEGIN
 	 SELECT @DepartmentTimeZone = Min(Time_Zone)
 	  	 FROM Departments a
 	  	 Join Prod_Lines b on b.Dept_Id = a.Dept_Id 
 	  	 JOIN Prod_Units c on c.PL_Id = b.PL_Id
 	  	 JOIN @Units d on d.PUId = c.PU_Id
 	 IF  @DepartmentTimeZone Is Null
 	 BEGIN
 	  	 SELECT @DepartmentTimeZone = Min(Time_Zone)
 	  	 From Departments a
 	 END
 	 SELECT  @DepartmentTimeZone = Coalesce(@DepartmentTimeZone,'UTC')
 	 SET @Start_Time = DATEADD(millisecond,-DatePART(millisecond,@Start_Time),@Start_Time)
 	 SET @Start_Time = DATEADD(Second,-DatePART(Second,@Start_Time),@Start_Time)
 	 SET @Start_Time = DATEADD(Minute,-DatePART(Minute,@Start_Time),@Start_Time)
 	 SET @Start_Time = DATEADD(Hour,-DatePART(Hour,@Start_Time),@Start_Time)
 	 SELECT @Start_Time = dbo.fnServer_CmnConvertToDbTime(@Start_Time,@DepartmentTimeZone)
END
IF @crewOn = 1
BEGIN
 	 INSERT INTO @Results(Id ,schedType,content,machine,shift_name,start_time,end_time,Line)
 	  	  select  convert(nvarchar(50),sh.CS_Id), 'crew', 
 	  	  	  	 CASE WHEN sh.Comment_Id is not null THEN '&bigstar;&nbsp;' ELSE '' END 
 	  	  	  	  	 +  c.name +'['+pub.pu_desc+':'+pl.PL_Desc+']',
 	  	  	  	 pub.pu_desc+'['+pl.PL_Desc+']', 
 	  	  	  	 s.name ,sh.start_time,sh.end_time,pl.PL_Desc
 	  	   from Crew_Schedule sh 
 	  	    join Shifts_Crew_schedule_mapping sm on (sm.Crew_Schedule_Id= sh.CS_Id)
 	  	    join Shifts s on (s.id = sm.Shift_Id)
 	  	    join CrewSchedule_Crew_Mapping csm on (csm.Crew_Schedule_Id= sh.CS_Id)
 	  	    join Crews c on (c.id = csm.Crew_Id)
 	  	    JOIN @Units u on u.puid = sh.pu_Id
 	  	    join Prod_Units pub on (u.PUId = pub.PU_Id)
 	  	    join Prod_Lines pl on pub.PL_Id = pl.PL_Id
 	  	   where 
 	  	    (sh.start_time < @End_Time  and sh.end_time > @Start_Time )
END
IF @offTimeOn = 1
BEGIN 
 	 INSERT INTO @Results(Id ,schedType,content,machine,shift_name,start_time,end_time,Line)
 	  	 select  	  convert(nvarchar(50),d.TEDet_Id), 'offtime',
 	  	  	 pub.PU_Desc + '('+ Coalesce(r.Event_Reason_Name,'') +')', 
 	  	  	 pub.pu_desc + '['+ pl.PL_Desc +']',
 	  	    '', d.Start_Time, coalesce(d.End_Time,@end_Time),pl.PL_Desc
 	  	   from  	  Timed_Event_Details d 
 	  	    JOIN @Units u on u.puid = d.pu_Id
 	  	    join Prod_Units pub on u.puid = pub.PU_Id
 	  	    join Prod_Lines pl on pub.PL_Id = pl.PL_Id
 	  	    left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
 	  	  where  
 	  	    (d.start_time < @End_Time  and (d.end_time > @Start_Time  or d.End_Time Is Null))
END
IF  @downTime = 1
BEGIN
 	 INSERT INTO @Results(Id ,schedType ,content,machine,shift_name,start_time,end_time,Line)
 	  	 select  	  convert(nvarchar(50),d.TEDet_Id) ,  	 'downtime',
 	  	  	 pub.PU_Desc+'('+Coalesce(r.Event_Reason_Name,'')+')', 
 	  	  	 pub.pu_desc+'['+pl.PL_Desc+']',
 	  	    '', d.Start_Time , coalesce(d.End_Time,@end_Time), pl.PL_Desc
 	  	   from  	  Timed_Event_Details d 
 	  	    JOIN @Units u on u.puid = d.pu_Id
 	  	    join Prod_Units pub on u.puid = pub.PU_Id
 	  	    join Prod_Lines pl on pub.PL_Id = pl.PL_Id
 	  	    left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
 	  	  where  
 	  	    (d.start_time < @End_Time  and (d.end_time > @Start_Time  or d.End_Time Is Null))
END
IF @nonProdTime = 1 and @reasonId = 0
BEGIN
 	 INSERT INTO @Results(Id ,schedType,content,machine,shift_name,start_time,end_time,Line)
 	  	 select  	  convert(nvarchar(50),d.NPDet_Id),
 	  	   CASE WHEN  d.NPT_Group_Id > 0 THEN 'notprodgroup' ELSE 'notprod' END, 
 	  	   CASE WHEN d.Comment_Id is not null THEN '&bigstar;&nbsp;'ELSE ''END
 	  	  	 + pub.PU_Desc+'('+ coalesce(r4.Event_Reason_Name,r3.Event_Reason_Name,r2.Event_Reason_Name,r.Event_Reason_Name,'') + ')', 
 	  	    pub.pu_desc+'['+pl.PL_Desc+']',
 	  	    '', d.Start_Time, d.End_Time ,pl.PL_Desc
 	  	   from  	  NonProductive_Detail d 
 	  	    JOIN @Units u on u.puid = d.pu_Id
 	  	    join Prod_Units pub on u.puid = pub.PU_Id
 	  	    join Prod_Lines pl on pub.PL_Id = pl.PL_Id
 	  	    left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
 	  	    left join Event_Reasons r2 on r2.Event_Reason_Id = d.Reason_Level2
 	  	    left join Event_Reasons r3 on r3.Event_Reason_Id = d.Reason_Level3
 	  	    left join Event_Reasons r4 on r4.Event_Reason_Id = d.Reason_Level4
 	  	  where  
 	  	   (d.start_time < @End_Time  and d.end_time > @Start_Time )
END
IF  @nonProdTime = 1 and @reasonId > 0
BEGIN
 	 INSERT INTO @Results(Id ,schedType,content,machine,shift_name,start_time,end_time,Line)
 	  	 SELECT distinct convert(nvarchar(50),d.NPDet_Id),
 	  	    CASE WHEN  d.NPT_Group_Id > 0 THEN 'notprodgroup' ELSE 'notprod' END, 
 	  	  	 CASE WHEN d.Comment_Id is not null THEN '&bigstar;&nbsp;' ELSE '' END 
 	  	  	  	 + pub.PU_Desc + '(' + coalesce(r4.Event_Reason_Name,r3.Event_Reason_Name,r2.Event_Reason_Name,r.Event_Reason_Name,'') +')', 
 	  	  	 pub.pu_desc+'['+pl.PL_Desc+']',
 	  	  	  '', d.Start_Time, d.End_Time, pl.PL_Desc
 	  	 FROM  	  NonProductive_Detail d 
 	  	    JOIN @Units u on u.puid = d.pu_Id
 	  	  	 join Prod_Units pub on u.puid = pub.PU_Id
 	  	  	 join Prod_Lines pl on pub.PL_Id = pl.PL_Id
 	  	  	 left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
 	  	  	 left join Event_Reasons r2 on r2.Event_Reason_Id = d.Reason_Level2
 	  	  	 left join Event_Reasons r3 on r3.Event_Reason_Id = d.Reason_Level3
 	  	  	 left join Event_Reasons r4 on r4.Event_Reason_Id = d.Reason_Level4
 	   where  
 	    d.Event_Reason_Tree_Data_Id = @reasonId    AND (d.start_time < @End_Time  and d.end_time > @Start_Time )
END
SELECT  id ,schedType,content,machine,shift_name,
 	 start_time= Case WHEN start_time < @Start_Time THEN @Start_Time ELSE start_time END,
 	 end_time= Case WHEN end_time > @End_Time THEN @End_Time ELSE end_time END,
 	 Line
 	 FROM @Results
order by machine,start_time
