  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_DowntimeData  
 @PULId integer,  
 @PUId  integer,    
 @Starttime      datetime,  
 @Endtime datetime   
AS  
  
SET NOCOUNT ON  
  
declare @Column_Name varchar(50),  
 @Step  varchar(50)  
/*  
SELECT @PULId = 0  
SELECT @PUId = 40  
SELECT @Starttime = '2001-08-01 7:00:00.000'  
SELECT @Endtime = '2001-08-11 19:00:00.000'  
*/  
  
DECLARE @event_details TABLE(  
 start_time datetime,  
 end_time datetime,  
 duration float,  
 pu_desc varchar(50),  
 reason1 varchar(50),  
 reason2 varchar(50),  
 var_desc varchar(50),  
 result varchar(50),  
 fault_code varchar(10),  
 fault_desc varchar(50)  
 )  
  
DECLARE @column_names TABLE(  
 var_desc varchar(50))  
  
DELETE FROM Local_DowntimeData  
  
IF @PULId > 0  
BEGIN  
 insert into @event_details(start_time, end_time, duration, pu_desc,  
  reason1, reason2, var_desc, result, fault_code, fault_desc)  
        select start_time, end_time, duration, pus.pu_desc, e1.event_reason_name,  
    e2.event_reason_name, v.var_desc, ts.result, tef.tefault_value, tef.tefault_name  
        from [dbo].timed_event_details t   
            left outer join [dbo].prod_units pu  
             on t.pu_id = pu.pu_id  
     left outer join [dbo].prod_units pus  
     on t.source_pu_id = pus.pu_id  
            left outer join [dbo].event_reasons e1  
             on t.reason_level1 = e1.event_reason_id  
            left outer join [dbo].event_reasons e2  
             on t.reason_level2 = e2.event_reason_id  
            left outer join [dbo].tests ts  
         on t.start_time = ts.result_on  
            left outer join [dbo].variables v  
                on ts.var_id = v.var_id  
            left outer join [dbo].timed_event_fault tef  
   on t.TEFault_Id = tef.TEFault_Id  
        where (t.start_time >= @Starttime and t.start_time <= @Endtime) and t.pu_id = @PULId  
END  
ELSE  
IF @PULId <= 0 and @PUId > 0  
BEGIN  
 insert into @event_details(start_time, end_time, duration, pu_desc,  
  reason1, reason2, var_desc, result, fault_code, fault_desc)  
        select start_time, end_time, duration, pu_desc, e1.event_reason_name,  
    e2.event_reason_name, v.var_desc, ts.result, tef.tefault_value, tef.tefault_name  
        from [dbo].timed_event_details t   
            left outer join [dbo].prod_units pu  
             on t.source_pu_id = pu.pu_id  
            left outer join [dbo].event_reasons e1  
             on t.reason_level1 = e1.event_reason_id  
            left outer join [dbo].event_reasons e2  
             on t.reason_level2 = e2.event_reason_id  
            left outer join [dbo].tests ts  
        on t.start_time = ts.result_on  
            left outer join [dbo].variables v  
                on ts.var_id = v.var_id  
            left outer join [dbo].timed_event_fault tef  
   on t.TEFault_Id = tef.TEFault_Id  
        where (t.start_time >= @Starttime and t.start_time <= @Endtime) and t.source_pu_id = @PUId  
END  
  
insert into @column_names(var_desc)  
 select distinct var_desc from @event_details  
  
INSERT INTO [dbo].Local_DowntimeData(Start_Time, End_Time, Location, Reason1, Reason2, Fault_Code, Fault_Desc,  
    Uptime, Downtime, Downtime_Primary, Minor_Stop, Breakdown, Uptime_LT2,  
    Category, Schedule, Subsystem, Production_Status, Shift, Team)  
 SELECT start_time, end_time, pu_desc, reason1, reason2, fault_code, fault_desc,  
  MAX(CASE var_desc WHEN 'Uptime' THEN result ELSE '' END) as Uptime,  
  MAX(CASE var_desc WHEN 'Downtime' THEN result ELSE '' END) as Downtime,  
  MAX(CASE var_desc WHEN 'Downtime Primary' THEN result ELSE '' END) as 'Downtime Primary',  
  MAX(CASE var_desc WHEN 'Minor Stops' THEN result ELSE '' END) as 'Minor Stops',  
  MAX(CASE var_desc WHEN 'Breakdown' THEN result ELSE '' END) as Breakdown,  
  MAX(CASE var_desc WHEN 'Uptime < 2 min' THEN result ELSE '' END) as 'Uptime < 2 min',  
  MAX(CASE var_desc WHEN 'GKC Category' THEN result ELSE '' END) as Category,  
  MAX(CASE var_desc WHEN 'GKC Schedule' THEN result ELSE '' END) as Schedule,  
  MAX(CASE var_desc WHEN 'GKC Subsystem' THEN result ELSE '' END) as Subsystem,  
  MAX(CASE var_desc WHEN 'Production Status' THEN result ELSE '' END) as 'Production Status',  
  MAX(CASE var_desc WHEN 'Shift Downtime' THEN result ELSE '' END) as Shift,  
  MAX(CASE var_desc WHEN 'Team Downtime' THEN result ELSE '' END) as Team  
 FROM @event_details  
 GROUP BY start_time, end_time, duration, pu_desc, reason1, reason2, fault_code, fault_desc  
  
  
SET NOCOUNT ON  
