  
/*  
Stored Procedure: spLocal_Rpt_SGVDDS  
Author:   Fran Osorno  
Date Created:  Dec. 17, 2004  
  
Description:  
=========  
This procedure will return data for the Plant Line Supply DDS  
  
  
INPUTS:  
  @pl_desc    VARCHAR(50),  --This is the pl_desc of the call  
  @DaysBack  INT,   --This is the number of days back from today to run the queries for --added Oct. 30, 2004  
  @GetRateLoss  VARCHAR(50),  --This is Yes to also get rate loss data  
  @OtherDTUnits  NVARCHAR(4000), --This is the other units for Downtime    --added Oct. 14, 2004  
  @LinesNeeded  NVARCHAR(4000), --This is the list of lines to include in the TI/PR calc  
  @PackersNeeded NVARCHAR(4000), --This is the list of packers to include in the TI/PR calc  
  @GetData  VARCHAR(50)  --This is which type of data to return  
        -- All is TestData, ProdData and Downtime  
        -- TestData just the test data  
        -- ProdData just the Production data  
        -- Downtime just the Downtime Data  
  
CALLED BY:  RptCvtgShiftToTime..xlt (Excel/VBA Template)  
  
CALLS: dbo.fnLocal_GlblParseInfo  
  
Rev Change Date  Who  What  
=== =========== ====  =====  
1 Dec 17, 2004  FGO  Placed into service  
2 14-OCT-2009 Mike Thomas Updated for Cape G. SGV  
*/  
  
/*  
EXEC spLocal_Rpt_SGVDDS 'TT SGV','2009-10-13 00:00:00','2009-10-14 00:00:00','All'  
*/  
  
  
CREATE PROCEDURE [dbo].[spLocal_Rpt_SGVDDS]  
  @pldescSGV  VARCHAR(50),  --this is the line description for the SGV's  
--  @pldescAW  VARCHAR(50),  --this is the line description for the Auto wrapper  
  @start_time  DATETIME,  --this is the report start date/time  
  @end_time  DATETIME,  --this is the report end date/time   
  @GetData  VARCHAR(50)  --this is the type of data to return  
AS  
  
DECLARE  
  @Max_TEDet_ID  INT,   --this is the max of the TEDet_id  
  @Min_TEDet_ID  INT,   --this is the min of the TEDet_id  
  @LinkStr  VARCHAR(100),  --this is the string to pass  dbo.fnLocal_GlblParseInfo  
  @DEBUG_STATUS INT   --1=yes 0=no  
  
/* set the other variables */  
 SET @DEBUG_STATUS = 0  
  
/* Declare the Tables */  
 DECLARE @puid TABLE(   
  pu_id  INT,   --this is the pu_id of the relaiblity units  
  pu_desc  VARCHAR(50),  --this is the pu_desc  
  var_id  INT  --this is the var_id of the reliability unit for the Node Location Variable  
  
 )  
 CREATE TABLE #DTData (  
  TEDet_Id  INT,   --this is the id from timed_event_details      
  pu_id   INT,   --this is the pu_id of the event       
  [Production Line] VARCHAR(50),  --this is the production line description      
  [Production Unit] VARCHAR(50),  --This is the pu_desc  
  [Location]  VARCHAR(50),  --this is the location of the event       
  [NodeNumber] INT,   --this is the Node of the downtime  
  [Node]  VARCHAR(100),  --text of node name from waste_event_fault table  
  [Scheduled Unit]  INT,   --this is the scheduled unit   
  [Team]   VARCHAR(10),  --the event team  
  [Shift]   VARCHAR(10),  --the event shift  
  [Start Time]  DATETIME,  --the event start_time  
  [End Time]  DATETIME,  --the event end_time,  
  Duration  FLOAT(8),  --the event duration  
  Uptime   FLOAT(8),  --this uptime   
  Jobs   INT,   --the number of jobs the vehical had  
  [Minor Stops]  INT,   --the number of minor stops  
  [Process Failures] INT,   --the number of process failures  
  [Equipment Failures] INT,   --the number of Equipement Failures  
  [MS Time]  FLOAT(8),  --the duration if a minor stop  
  [PF Time]  FLOAT(8),  --the duration if a process failure  
  [EF Time]  FLOAT(8),  --the duration if a equipment failure  
  [Failure Mode]  VARCHAR(50),  --the events Failure Mode  
  [Failure Mode Cause] VARCHAR(50),  --the events Failure Mode Cause  
  Schedule  VARCHAR(50),  --the Reason Category for Scheduled      
  Category  VARCHAR(50),  --the Reason Category for Category      
  [Sub System]  VARCHAR(50),  --the Reason Category for Sub System      
  [Group Cause]  VARCHAR(50),  --the Reason Category for Group Cause      
  [Is a Stop]  INT,   --A Stop 1=Stop         
  [Is Edited]  INT,   --Edited = 1         
  Comment  TEXT   --this is the event comment       
  )  
  
  
 CREATE CLUSTERED INDEX  dtd_PUId_StartTime  
  ON #DTData(pu_id,[Start Time],[End Time])  
  
 DECLARE @TECategories TABLE(  
  TEDet_Id  INT,   --this is the TEDet_id  
  ERC_Id   INT   --this is the ERC_Id  
 )  
  
 DECLARE @plid TABLE(  
  pl_id   INT   --this is thepl_id of the line descriptions  
 )  
  
 DECLARE @Jobs TABLE(  
  [Job Location]  VARCHAR(50),  --this is the pu_desc of the jobs pu_id  
  [Job Time]  DATETIME,  --this is the time of the job competed  
  [Vehicle]  INT   --this is the Vechicle used for the Job  
 )  
 DECLARE @VehicleJobs TABLE(  
  Vehicle   VARCHAR(50),  --this is the Vechicle   
  Jobs   INT   --this is the count of the jobs  
 )  
/* set @LinkStr */  
 SET @LinkStr = 'ScheduleUnit='  
IF @GetData = 'All' OR @GetData = 'Downtime'  
 BEGIN  
  /*get @plid */  
   INSERT @plid(pl_id)  
    SELECT  pl_id FROM prod_lines WITH (NOLOCK)WHERE pl_desc = @pldescSGV  
--   INSERT @plid(pl_id)  
--    SELECT pl_id FROM prod_lines WITH (NOLOCK)WHERE pl_desc = @pldescAW  
   IF @DEBUG_STATUS = 1  
    BEGIN  
     SELECT * FROM @plid  
    END  
  
  /* Fill@puid */  
   /* get the pu_id */  
    INSERT INTO @puid(pu_id)  
     SELECT pu_id FROM prod_units AS pu  
      JOIN @plid AS plid ON (plid.pl_id = pu.pl_id)  
     WHERE pu_desc LIKE '%Reliability'  
   /* get the var_id */  
    UPDATE @puid  
      SET var_id = v.var_id  
     FROM variables AS v  
      LEFT JOIN @puid AS puid ON (puid.pu_id = v.pu_id)  
      LEFT JOIN pu_groups as pug ON (pug.pug_id = v.pug_id)  
     WHERE pug_desc = 'Downtime Variables'  
      AND var_desc = 'Node'  
  
  
   IF @DEBUG_STATUS = 1  
    BEGIN  
     SELECT * FROM @puid  
    END  
  
  /* get the downtime events */  
   /* get the event data */  
    INSERT INTO #DTData(TEDet_Id,pu_id,[Production Unit],[Location],[Start Time],[End Time],Duration,[Failure Mode],[Failure Mode Cause],[Production Line],uptime,[Scheduled Unit])  
     SELECT ted.TEDet_id,pu1.pu_id,pu1.pu_desc,pu2.pu_desc,start_time,end_time,  
      duration AS [Downtime],   
      [Failure Mode] =   
       CASE  
        WHEN er1.Event_Reason_Name  IS NOT NULL THEN  er1.Event_Reason_Name  
        ELSE 'Not Edited'  
       END,  
      [Failure Mode Cause]=  
       CASE  
        WHEN er2.Event_Reason_Name IS NOT NULL THEN er2.Event_Reason_Name  
        ELSE 'Not Edited'  
       END,  
      pl_desc,uptime,GBDB.dbo.fnLocal_GlblParseInfo(pu1.Extended_info,@LinkStr)  
     FROM timed_event_details AS ted WITH (NOLOCK)  
      LEFT JOIN event_reasons AS er1 ON (er1.event_reason_id = ted.reason_level1)  
      LEFT JOIN event_reasons AS er2 ON (er2.event_reason_id = ted.reason_level2)  
      LEFT JOIN prod_units AS pu1 ON (pu1.pu_id = ted.pu_id)  
      LEFT JOIN prod_units AS pu2 ON (pu2.pu_id = ted.source_pu_id)  
      LEFT JOIN @puid AS puid ON (puid.pu_id = ted.pu_id)  
      LEFT JOIN prod_lines as pl ON (pl.pl_id = pu1.pl_id)  
     WHERE (ted.pu_id = puid.pu_id)  
      AND (ted.start_time >= @start_time and (ted.end_time <= @end_time  OR ted.end_time is NULL))  
   /* get the Node Locations */  
    UPDATE #DTData  
     SET NodeNumber = result  
      FROM #DTData AS dtd  
       LEFT JOIN @puid AS puid ON (puid.pu_id = dtd.pu_id)  
       LEFT JOIN tests ON (tests.result_on = dtd.[start time] AND tests.var_id = puid.var_id)  
  
   -- Get Node text  
    UPDATE #DTData  
     SET Node = WEFault_Name  
      FROM #DTData dtd  
       LEFT JOIN waste_event_fault wef ON wef.WEFault_value = dtd.NodeNumber  
  
   /* get the max and min of the TEDet_Id in #DTData */  
    SELECT @Max_TEDet_Id  = MAX(TEDet_Id) + 1,  
     @Min_TEDet_Id = MIN(TEDet_Id) - 1  
    FROM #DTData  
  
   /* Going to only do this once b/c its really expensive (??) to query from Local_Timed_Event_Categories */  
    INSERT INTO @TECategories ( TEDet_Id,ERC_Id)  
     SELECT tec.TEDet_Id,tec.ERC_Id  
     FROM #DTData AS td  
      INNER JOIN Local_Timed_Event_Categories AS tec ON (td.TEDet_Id = tec.TEDet_Id)  
       AND tec.TEDet_Id > @Min_TEDet_Id  
       AND tec.TEDet_Id < @Max_TEDet_Id  
   /*Set all the Schedule,Category,Sub System and Group Cause to Not Edited */  
    UPDATE #DTData  
     SET [Schedule] = 'Not Edited',  
      [Category] = 'Not Edited',  
      [Sub System] = 'Not Edited',  
      [Group Cause] = 'Not Edited',  
      [IS A Stop] =1,  
      [Is Edited] = 0  
   /*updated [Is Edited] = 1 if [Failure Mode Cause] = 'Not Edited' */  
    UPDATE #DTData  
     SET [Is Edited] = 1  
     WHERE [Failure Mode Cause] <> 'Not Edited'    /* update Schedule in #DTData */  
    UPDATE td  
     SET [Schedule] = erc.ERC_Desc  
     FROM #DTData AS td  
      INNER JOIN @TECategories AS tec ON (td.TEDet_Id = tec.TEDet_Id)  
      INNER JOIN Event_Reason_Catagories AS erc ON (tec.ERC_Id = erc.ERC_Id)  
       AND erc.ERC_Desc LIKE 'Schedule:%'  
   /* update Category  in #DTData */  
    UPDATE td  
     SET [Category] = erc.ERC_Desc  
     FROM #DTData AS td  
      INNER JOIN @TECategories AS tec ON (td.TEDet_Id = tec.TEDet_Id)  
      INNER JOIN Event_Reason_Catagories AS erc ON (tec.ERC_Id = erc.ERC_Id)        AND erc.ERC_Desc LIKE 'Category:%'  
   /* update SubSystem in #DTData */  
    UPDATE td  
     SET [Sub System] = erc.ERC_Desc  
     FROM #DTData AS td  
      INNER JOIN @TECategories AS tec ON (td.TEDet_Id = tec.TEDet_Id)  
      INNER JOIN Event_Reason_Catagories AS erc ON (tec.ERC_Id = erc.ERC_Id)  
       AND erc.ERC_Desc LIKE 'SubSystem:%'  
   /* update GroupCause in #DTData */  
    UPDATE td  
     SET [Group Cause] = erc.ERC_Desc  
     FROM #DTData AS td  
      INNER JOIN @TECategories AS tec ON (td.TEDet_Id = tec.TEDet_Id)  
      INNER JOIN Event_Reason_Catagories AS erc ON (tec.ERC_Id = erc.ERC_Id)  
       AND erc.ERC_Desc LIKE 'GroupCause:%'  
   /* UPDATE Comment in #DTData */  
    UPDATE #DTData  
     SET Comment =   
      CASE  
       WHEN  WTC_Type = 2 or WTC_Type = 1  
        THEN CONVERT(VARCHAR(255),comment_text)  
       ELSE  
        'No Comment Entered'  
      END  
     FROM waste_n_timed_comments  
     WHERE    TEDet_ID = WTC_source_ID  
    UPDATE #DTData      SET Comment = 'No Comment Entered'  
      WHERE comment IS NULL      
   /*Update MS and Process Failures  and Equipment Failures*/  
    UPDATE #DTData  
     SET [Minor Stops] =   
      CASE  
       WHEN duration <10 AND (Schedule = 'Not Edited' OR Schedule LIKE 'Unscheduled%') THEN 1  
       ELSE 0  
      END  
    UPDATE #DTData   
     SET [Process Failures] =   
      CASE  
       WHEN duration >=10 AND ((Schedule = 'Not Edited' OR Schedule LIKE 'Unscheduled%')  
        AND (Category = 'Not Edited' OR Category NOT LIKE 'Mechanical%')) THEN 1  
       ELSE 0  
      END  
    UPDATE #DTData   
     SET [Equipment Failures] =   
      CASE  
       WHEN duration >=10 AND ((Schedule = 'Not Edited' OR Schedule LIKE 'Unscheduled%')  
        AND (Category LIKE 'Mechanical%')) THEN 1  
       ELSE 0  
      END  
    UPDATE #DTData  
     SET [MS Time] =   
       CASE  
        WHEN [Minor Stops] = 1 THEN duration  
        ELSE 0  
       END,  
      [PF Time] =  
       CASE  
        WHEN [Process Failures] =1 THEN duration  
        ELSE 0  
       END,  
      [EF Time] =  
       CASE  
        WHEN [Equipment Failures] =1 THEN duration  
        ELSE 0  
       END    
   /* update the team and shift of #DTData */  
  
    UPDATE #DTData  
     SET Team = Crew_desc,  
      Shift = Shift_desc  
     FROM #DTData AS td,crew_schedule AS cs  
     WHERE  td.[start time]>= cs.start_time and td.[start time] <= cs.end_time  
      AND cs.pu_id = td.[Scheduled Unit]  
  
  
   IF @DEBUG_STATUS = 1  
    BEGIN  
     SELECT * FROM #DTData  
    END  
 END  
  
  
/*get the Jobs Data */  
 IF @GetData = 'All' OR @GetData = 'Jobs'  
  BEGIN  
   /*empty @plid */     
    DELETE @plid  
   /*refill @plid */  
    INSERT @plid(pl_id)  
    SELECT  pl_id FROM prod_lines WHERE pl_desc = @pldescSGV  
   /* empty @puid */  
    DELETE @puid  
   /* reFill @puid */  
    INSERT INTO @puid(pu_id,pu_desc)  
     SELECT pu_id,pu_desc FROM prod_units AS pu  
      JOIN @plid AS plid ON (plid.pl_id = pu.pl_id)  
     WHERE pu_desc LIKE '%Jobs'  
   /* get the var_id */  
    UPDATE @puid  
      SET var_id = v.var_id  
     FROM variables AS v  
      LEFT JOIN @puid AS puid ON (puid.pu_id = v.pu_id)  
      LEFT JOIN pu_groups as pug ON (pug.pug_id = v.pug_id)  
     WHERE pug_desc = 'Attributes'  
      AND var_desc = 'SGV Number'  
  
    IF @DEBUG_STATUS = 1  
     BEGIN  
      SELECT * FROM @puid  
     END  
   /*get the count of event for all the the records in @puid */  
    INSERT INTO @Jobs([Job Location],[Job Time],[Vehicle])  
     SELECT pu_desc,timestamp,result  
      FROM events  
       JOIN @puid AS puid ON (puid.pu_id = events.pu_id)  
       LEFT JOIN tests ON (tests.result_on = events.timestamp AND tests.var_id = puid.var_id)  
      WHERE (timestamp >= @start_time and timestamp <=@end_time)  
  
   /* fill @VechicleJobs */  
    INSERT INTO @VehicleJobs(Vehicle,Jobs)  
     SELECT Vehicle,Count(Vehicle)  
      FROM @Jobs  
      WHERE Vehicle IS NOT NULL  
      GROUP BY Vehicle   
   /* update the Vehicle field to match the Reliability Unit Name */  
    UPDATE @VehicleJobs  
     SET Vehicle = 'SGV'+vehicle + ' Reliability'  
  
  
    IF @DEBUG_STATUS =1  
     BEGIN  
      SELECT * from @VehicleJobs  
     END  
  END  
  
ReturnData:  
/*report our the data */  
 IF @GetData = 'All'  
  BEGIN  
   /*Update #DTData for jobs */  
    UPDATE #DTData  
     SET Jobs = vj.Jobs  
     FROM #DTData as dtd  
      LEFT JOIN @VehicleJobs AS vj ON (vj.vehicle = dtd.[Production Unit])  
  END  
 IF @GetData = 'All' OR @Getdata = 'Jobs'  
  BEGIN  
   SELECT * FROM @Jobs  
  END  
 IF @GetData = 'All' OR @GetData = 'Downtime'  
  BEGIN  
   SELECT   [Production Line],[Production Unit],[Location],[Node],[Team],[Shift],[Start Time],  
    [End Time],Duration,Uptime,Jobs,[Minor Stops],[Process Failures],[Equipment Failures],[MS Time], [PF Time],[EF Time],  
    [Failure Mode],[Failure Mode Cause],Schedule,Category,[Sub System],  
    [Group Cause],[Is a Stop],[Is Edited],Comment  
   FROM #DTData  
  END  
DROP TABLE #DTData  
  
  
GRANT  EXECUTE  ON [dbo].[spLocal_Rpt_SGVDDS]  TO [comxclient]  
