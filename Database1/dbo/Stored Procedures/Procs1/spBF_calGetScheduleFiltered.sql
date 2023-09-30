-- =============================================
-- Author: 	  	 <502406286, Alfredo Scotto>
-- Create date: <Create Date,,>
-- Description: 	 <Description,,>
-- =============================================
CREATE PROCEDURE dbo.spBF_calGetScheduleFiltered
        @Start_Time datetime,
        @End_Time datetime,
        @crewOn int,
        @operationOn int,
        @offTimeOn int,
        @downTime int,
        @nonProdTime int,
        @reasonId int
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
  DECLARE @startTime datetime;
  declare @endTime datetime;
  SET @startTime = dbo.fnBF_calDateTimeFromParts(DATEPART(year,@Start_Time),DATEPART(month,@Start_Time),DATEPART(day,@Start_Time), 0,0,0,0) ;
  if @End_Time is NULL
    SET @endTime = dbo.fnBF_calDateTimeFromParts(DATEPART(year,@Start_Time),DATEPART(month,@Start_Time),DATEPART(day,@Start_Time), 23,59,59,999) ;
  else
    SET @endTime = dbo.fnBF_calDateTimeFromParts(DATEPART(year,@End_Time),DATEPART(month,@End_Time),DATEPART(day,@End_Time), 23,59,59,999) ;
 select  convert(nvarchar(50),sh.CS_Id) as id,
 'crew' as schedType, 
 content = Case WHEN sh.Comment_Id is not null THEN '&bigstar;&nbsp;'
 	  	  	 ELSE ''
 	  	  	 END  + c.name+'['+pub.pu_desc+':'+pl.PL_Desc+ ']',
  pub.pu_desc+ '['+pl.PL_Desc+']' as machine, 
  s.name as shift_name, 
  sh.start_time, 
  sh.end_time, 
  pl.PL_Desc as line
  from Crew_Schedule sh 
   join Shifts_Crew_schedule_mapping sm on (sm.Crew_Schedule_Id= sh.CS_Id)
   join Shifts s on (s.id = sm.Shift_Id)
   join CrewSchedule_Crew_Mapping csm on (csm.Crew_Schedule_Id= sh.CS_Id)
   join Crews c on (c.id = csm.Crew_Id)
   join Prod_Units pub on (sh.PU_Id = pub.PU_Id)
   join Prod_Lines pl on pub.PL_Id = pl.PL_Id
  where @crewOn = 1 and (( sh.start_time between @startTime and @endTime or ( sh.start_time <= @endTime and sh.end_time > @endTime ) ) or ( sh.start_time <= @startTime and sh.end_time >= @startTime ) )
UNION 
select 	 convert(nvarchar(50),d.TEDet_Id) as id, 
 	  	 'offtime' as schedType, pub.PU_Desc+'('+r.Event_Reason_Name_Local+')' as content, 
 	  	 pub.pu_desc+'['+pl.PL_Desc+']' as machine,
 	  	 '' as shift_name, d.Start_Time as start_time, d.End_Time as end_time, pl.PL_Desc as line
  from 	 Timed_Event_Details d 
   join Prod_Units pub on d.PU_Id = pub.PU_Id
   join Prod_Lines pl on pub.PL_Id = pl.PL_Id
   left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
 where @offTimeOn = 1 and d.End_Time is not null and d.Start_Time >= @startTime
   and d.End_Time <= @endTime
UNION
select 	 convert(nvarchar(50),d.TEDet_Id) as id, 'downtime' as schedType,
  pub.PU_Desc+'('+r.Event_Reason_Name_Local+')' as content, 
  pub.pu_desc+'['+pl.PL_Desc+']' as machine,
   '' as shift_name, d.Start_Time as start_time, d.End_Time as end_time, pl.PL_Desc as line
  from 	 Timed_Event_Details d 
   join Prod_Units pub on d.PU_Id = pub.PU_Id
   join Prod_Lines pl on pub.PL_Id = pl.PL_Id
   left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
 where @downTime = 1 and d.End_Time is null and d.Start_Time >= @startTime and d.Start_Time <= @endTime
UNION
select 	 convert(nvarchar(50),d.NPDet_Id) as id, 'notprod' as schedType, 
 	 content = Case When d.Comment_Id is not null THEN 
 	  	 '&bigstar;&nbsp;' 
 	  	 ELSE
 	  	  	 ''
 	  	 END 
 	  	 + pub.PU_Desc +  Coalesce(coalesce(coalesce(coalesce(r4.Event_Reason_Name_Local,r3.Event_Reason_Name_Local),r2.Event_Reason_Name_Local),r.Event_Reason_Name_Local),'') +  ')',
  pub.pu_desc+'['+pl.PL_Desc+']' as machine,
   '' as shift_name, d.Start_Time as start_time, d.End_Time as end_time, pl.PL_Desc as line
  from 	 NonProductive_Detail d 
   join Prod_Units pub on d.PU_Id = pub.PU_Id
   join Prod_Lines pl on pub.PL_Id = pl.PL_Id
   left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
   left join Event_Reasons r2 on r2.Event_Reason_Id = d.Reason_Level2
   left join Event_Reasons r3 on r3.Event_Reason_Id = d.Reason_Level3
   left join Event_Reasons r4 on r4.Event_Reason_Id = d.Reason_Level4
 where @nonProdTime = 1 and @reasonId = 0 
   and d.Start_Time >= @startTime and d.End_Time <= @endTime
UNION 
select distinct 	 convert(nvarchar(50),d.NPDet_Id) as id, 'notprod' as schedType, 
 content =    CASE WHEN  d.Comment_Id is not null THEN
 	  	  	  	  	  	  	 '&bigstar;&nbsp;'
 	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	 ''
 	  	  	  	  	  	  	 END 
 	 + pub.PU_Desc +'(' +  coalesce(coalesce(coalesce(coalesce(r4.Event_Reason_Name_Local,r3.Event_Reason_Name_Local),r2.Event_Reason_Name_Local),r.Event_Reason_Name_Local),'') + ')',
  machine = pub.pu_desc+'['+pl.PL_Desc+']'
  , '' as shift_name,
   d.Start_Time as start_time,
    d.End_Time as end_time, 
 	 pl.PL_Desc as line
  from 	 NonProductive_Detail d 
   join Prod_Units pub on d.PU_Id = pub.PU_Id
   join Prod_Lines pl on pub.PL_Id = pl.PL_Id
   left join Event_Reasons r on r.Event_Reason_Id = d.Reason_Level1
   left join Event_Reasons r2 on r2.Event_Reason_Id = d.Reason_Level2
   left join Event_Reasons r3 on r3.Event_Reason_Id = d.Reason_Level3
   left join Event_Reasons r4 on r4.Event_Reason_Id = d.Reason_Level4,
   event_reason_tree_data et
  where @nonProdTime = 1 and @reasonId > 0 and et.Event_Reason_Tree_Data_Id = @reasonId AND
   ( ( et.Level1_Id = d.Reason_Level1 ) and 
     ( et.Level2_Id is null or et.Level2_Id = d.Reason_Level2 ) and 
     ( et.Level3_Id is null or et.Level3_Id = d.Reason_Level3 ) and 
     ( et.Level4_Id is null or et.Level4_Id = d.Reason_Level4 ) )
   AND d.Start_Time >= @startTime and d.End_Time <= @endTime
order by 4,6;
END
