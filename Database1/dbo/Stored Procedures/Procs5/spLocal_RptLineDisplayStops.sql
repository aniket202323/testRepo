  
  
/*    
--------------------------------------------------------------------  
Revision History  
--------------------------------------------------------------------  
2009-JAN-22 Jeff Jaeger  Rev1.00  
 -- Created.  
  
2009-FEB-13 Langdon Davis Rev1.10  
 -- Changed user to LineDisplay_User [password = jlyle4u].  
 -- Stripped out stuff not needed and simplified other code.  
  
2009-03-24 Jeff Jaeger Rev1.11  
 - Brought the definition of Unscheduled Stops up to date with what now exists in other reports.  
 - Added the NOT LIKE '%z_obs%' restriction to the population of @ProdUnits.  [Note we should still make a similar   
   restriction in the population of the line list done with a select out of the VB.]  
  
2009-05-21 Jeff Jaeger Rev1.12  
 - added code to pull ELP Stops into @ResultsSummary, @LineDisplaySummary and   
   a second result set.  
  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptLineDisplayStops  
--declare  
 @Line  varchar(100)  
  
AS  
  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-- Testing parameters.  
/*   
  
SELECT @Line =   
-- 'FF7A' -- 'FFF1' -- 'FFF7' -- 'FK68' -- 'FTL4' -- GB   
'OTT1' -- 'OKK1' -- OX  
-- 'MT65' -- 'MNN3' --  'MK70' -- MP  
-- 'GT01' -- 'GK21' -- Cape  
-- 'AC1' -- -- 'AK01' -- 'AT05' -- AY  
-- 'AZAL' -- AZ  
  
*/  
  
DECLARE   
@SchedUnscheduledId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
@SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
@StartTime      datetime,  
@EndTime       datetime,  
@CurrentShift      datetime,  
@DelayTypeRateLossStr   VARCHAR(100),  
@PUDelayTypeStr     VARCHAR(100),  
@CatELPID      int  
  
SELECT  
@SchedUnscheduledId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
@SchedBlockedStarvedId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
  
--Rev1.12  
@DelayTypeRateLossStr  = 'RateLoss',  
@PUDelayTypeStr    = 'DelayType=',  
@CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Category:Paper (ELP)')  
  
  
SELECT @EndTime = convert(varchar,getdate(),120)  
  
SELECT @CurrentShift =   
 (  
 select top 1   
  start_time   
 from crew_schedule   
 where start_time < @EndTime   
 and end_time >= @endtime  
 )  
  
SELECT @StartTime =   
 (  
 select top 1   
  start_time   
 from crew_schedule   
 where End_time = @CurrentShift  
 )  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 PUDesc            VARCHAR(100),  
 PLId             INTEGER,  
--Rev1.12  
 DelayType            varchar(100),  
 RowId             INTEGER IDENTITY  
 )  
  
DECLARE @RunSummary TABLE   
 (  
 [id]             int identity,  
 [ShiftStart]          datetime,  
 PLId             INTEGER,   
 PLDesc            varchar(50),  
 PUId             INTEGER,  
 PUDesc            varchar(50),  
--Rev1.12  
 DelayType            varchar(100),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 StopsCnt            int,  
 StopsELPCnt            int  
 primary key (puid, starttime)  
 )  
  
DECLARE @ProdLines table  
 (  
 PLId             int primary key,  
 PLDesc            VARCHAR(50),  
 deptid            int  
 )  
  
declare @LineDisplaySummary table   
 (   
 [OrderKey]           varchar(50),  
 [Line]            varchar(50),  
 [Unit]            VARCHAR(50),  
 [CurrentShiftCnt]         int,  
 [LastShiftCnt]          int,  
 [CurrentShiftELPCnt]         int,  
 [LastShiftELPCnt]          int  
 )  
  
declare @Dimensions table  
 (  
 Dimension     varchar(50),  
 Value       varchar(50),  
 StartTime     datetime,  
 EndTime      datetime,  
 PLID       int,  
 PUID       int  
 )  
  
insert @ProdLines   
 (  
 PLID,   
 PLDesc,  
 DeptID)  
select   
 PL_ID,   
 PL_Desc,  
 Dept_ID  
from dbo.prod_lines pl with (nolock)  
where right(pl.pl_desc, len(pl.pl_desc) -3) = @Line or pl.pl_desc = @Line  
option (keep plan)  
  
update pl set  
 pldesc = @Line  
from @prodlines pl  
  
INSERT @ProdUnits   
 (   
 PUId,  
 PUDesc,  --Rev1.12  
 DelayType,  
 PLId  
 )  
SELECT pu.PU_Id,  
 pu.PU_Desc,  
--Rev1.12  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
 pu.PL_Id  
FROM dbo.Prod_Units pu with (nolock)  
JOIN @ProdLines tpl   
ON pu.PL_Id = tpl.PLId  
and pu.Master_Unit is null  
JOIN dbo.Event_Configuration ec with (nolock)  
ON pu.PU_Id = ec.PU_Id  
AND ec.ET_Id = 2  
where (pu_desc like '%Converter Blocked/Starved'or pu_desc like '%Reliability')   
AND pu_desc not like '%z_obs%'  
option (keep plan)  
  
update pu set  
 PUDesc = replace(PUDesc,'Blocked/Starved','Reliability')   
from @produnits pu  
where PUDesc like '%Blocked/Starved%'  
  
update pu set  
 PUDesc = replace(PUDesc,' Reliability','')   
from @produnits pu  
  
insert @Dimensions   
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
SELECT distinct   
 'ShiftStart',  
 convert(varchar,@StartTime,120),  
 @StartTime,  
 @CurrentShift,  
 pu.PLID,  
 pu.PUId  
FROM @ProdUnits pu   
ORDER BY pu.PUId  
option (keep plan)  
  
insert @Dimensions   
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
SELECT distinct   
 'ShiftStart',  
 convert(varchar,@CurrentShift,120),  
 @CurrentShift,  
 @EndTime,  
 pu.PLID,  
 pu.PUId  
FROM @ProdUnits pu   
ORDER BY pu.PUId  
option (keep plan)  
  
INSERT INTO @RunSummary   
 (   
 [ShiftStart],  
 PLId,  
 PLDesc,  
 PUId,  
 pudesc,  
 DelayType,  
 StartTime,  
 EndTime  
 )  
SELECT distinct   
 d.Value,  
 pl.PLId,  
 pl.PLDesc,  
 pu.PUId,  
 pu.pudesc,  
 pu.DelayType,  
 d.StartTime,  
 d.EndTime  
FROM @dimensions d  
join @prodlines pl  
on pl.plid = d.plid  
JOIN @ProdUnits pu   
ON d.PUId = pu.PUId  
GROUP BY d.Value, pl.PLId, pl.pldesc, pu.PuId, pu.pudesc, pu.DelayType, d.StartTime, d.EndTime  
option (keep plan)  
  
update rs set  
 StopsCnt =  
  (  
  select   
   sum (  
   CASE   
   WHEN (rs1.pudesc not like '%converter%')  
--Rev1.12  
--   AND coalesce(erc.ERC_Id,@SchedUnscheduledID) in (@SchedUnscheduledId)   
   AND coalesce(erc.ERC_Id,@SchedUnscheduledID) = (@SchedUnscheduledId)   
   THEN 1  
   WHEN (rs1.pudesc like '%converter%' or rs1.pudesc like '%Converter Blocked/Starved')  
   AND coalesce(erc.ERC_Id,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
   THEN 1  
   ELSE 0  
   END  
   )  
  FROM @RunSummary rs1  
  join Timed_Event_Details TED WITH (NOLOCK)  
  on ted.pu_id = rs1.PUID    
  LEFT JOIN dbo.Timed_Event_Details ted2 with (nolock)  
  ON ted.PU_Id = ted2.PU_Id  
  AND ted.Start_Time = ted2.End_Time  
  AND ted.TEDet_Id <> ted2.TEDet_Id  
  left JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
  ON TED.event_reason_tree_data_id = ercd.event_reason_tree_data_id   
  left JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
  ON ercd.erc_id = erc.erc_id   
  where TED.START_TIME >= rs1.starttime  
  and TED.START_TIME < rs1.endtime   
  and  ted2.tedet_id is null  
--Rev1.12  
--  AND (  
--   erc.erc_desc = 'Schedule:Unscheduled'  
--   or erc.Erc_Desc = 'Schedule:Blocked/Starved'   
--   or erc.ERC_Desc is null  
--   )   
  and rs.[id] = rs1.[id]  
  )  
FROM @RunSummary rs  
option (maxdop 1)  
  
--/*  
--Rev1.12  
update rs set  
 StopsELPCnt =  
  (  
  select   
   sum (   
    CASE   
    WHEN rs1.DelayType <> @DelayTypeRateLossStr  
    and ercd.erc_id = @CatELPID  
    THEN 1  
    ELSE 0  
    END  
    )  
  FROM @RunSummary rs1  
  join Timed_Event_Details TED WITH (NOLOCK)  
  on ted.pu_id = rs1.PUID    
  LEFT JOIN dbo.Timed_Event_Details ted2 with (nolock)  
  ON ted.PU_Id = ted2.PU_Id  
  AND ted.Start_Time = ted2.End_Time  
  AND ted.TEDet_Id <> ted2.TEDet_Id  
  left JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
  ON TED.event_reason_tree_data_id = ercd.event_reason_tree_data_id   
  where TED.START_TIME >= rs1.starttime  
  and TED.START_TIME < rs1.endtime   
  and ted2.tedet_id is null  
--  and ercd.erc_id = @CatELPID  
  and rs.[id] = rs1.[id]  
  )  
FROM @RunSummary rs  
option (maxdop 1)  
--*/  
  
insert @LineDisplaySummary  
 (  
 [Line],  
 [Unit] )  
select  
 distinct   
 [pldesc],  
 [pudesc]  
from @RunSummary rs  
  
update lds set  
 [OrderKey] =   
  case  
  when [Unit] like '%Converter'  
  then [Line] + ':0'  
  else [Line] + ':1'  
  end,  
 LastShiftCnt =  
  coalesce(  
   (  
   select sum(StopsCnt)  
   from @runsummary rs  
   where rs.[pudesc] = lds.[Unit]  
   and rs.[ShiftStart] = @StartTime  
   ),0  
    ),  
 CurrentShiftCnt =  
  coalesce(  
   (  
   select sum(StopsCnt)  
   from @runsummary rs  
   where rs.[pudesc] = lds.[Unit]  
   and rs.[ShiftStart] = @CurrentShift  
   ), 0  
    ),  
 LastShiftELPCnt =  
  coalesce(  
   (  
   select sum(StopsELPCnt)  
   from @runsummary rs  
   where rs.[pudesc] = lds.[Unit]  
   and rs.[ShiftStart] = @StartTime  
   ),0  
    ),  
 CurrentShiftELPCnt =  
  coalesce(  
   (  
   select sum(StopsELPCnt)  
   from @runsummary rs  
   where rs.[pudesc] = lds.[Unit]  
   and rs.[ShiftStart] = @CurrentShift  
   ), 0  
    )  
from @LineDisplaySummary lds  
  
ReturnResultSets:  
  
--select 'rs', * from @RunSummary  
--select 'lds', * from @LineDisplaySummary  
  
--------------------------------------  
  
-- Total Stops results  
 select   
  [Unit],   
  [CurrentShiftCnt],  
  [LastShiftCnt]  
 from @LineDisplaySummary   
 order by [OrderKey], [Unit]  
  
-- ELP Stops results  
--Rev1.12  
 select   
  [Unit],   
  [CurrentShiftELPCnt],  
  [LastShiftELPCnt]  
 from @LineDisplaySummary   
 order by [OrderKey], [Unit]  
  
Finished:  
  
RETURN  
  
