  /*  
Stored Procedure: spLocal_PPRGenealogy  
Author:   Fran Osorno  
Date Created:  June 14, 2006  
  
Description:  
=========  
This procedure is used to collect the genealogy of all the converting stops for the PPR evaluation  
 This code will accept the following INPUTS  
  @LinesNeeded nvarchar(4000), --this is a string variable of all the pl_id's separated by |   
  @start  datetime,   --this is the report start  
  @end  datetime   --this is the report end  
  
 This code also uses the following extended_info and/or external_link for dbo.prod_units and dbo.pu_groups  
  dbo.Prod_units extended_info for Intermediates RollsUnit=Intr;  
  dbo.pu_groups external_link for Converting Lines Produciton Groups to include in the converting test data PPRGRP=Yes;  
  
 The RecordSets returned from the code are  
  1. Cvtg Rolls Ran  
   [ID],[TedID],[Line],[ULID],[Grand ULID],[PRID Running],[Grand PRID],[UWS Running],  
    [Running StartTime], [Running EndTime]  
  2. PPRTest Data  
   d.[ID],d.[Rolls ID],pprv.[Variable],d.Product,d.ResultOn,  
    d.Result,d.[Lower Reject Limit],d.[Lower Warning Limit],d.Target,  
    d.[Upper Warning Limit],d.[Upper Reject Limit]   
  3. Cvtg Stops data for only the Converter, but do include Rate Loss  
   d.[ID],d.[Line],d.[Production Unit],d.[Product],d.[Brand Code],  
    d.Location,d.[Event Type],d.StartTime,d.EndTime,d.[Effective Downtime],d.Fault,  
    d.[Failure Mode],d.[Failure Mode Cause],d.Schedule,  
    d.Category,d.Comment  
  4. Cvtg Test Data for when rolls where run  
   c.[RollsID],bv.[Variable],avg(convert(real,t.result)),c.[Lower Reject Limit],c.[Lower Warning Limit],c.Target,  
    c.[Upper Warning Limit],c.[Upper Reject Limit]  
  
This code calls the following functions  
 CALLS: GBDB.dbo.fnlocal_GlblParseInfo  
  
Change Date Who  What  
======== ==== =====  
06/14/06  FGO  Created procedure.  
06/15/06  FGO  Updated the recordsets to report out better for the VB code  
06/16/06  FGO  Updated the Cvtg Rolls Ran recordset for PPR Status  
*/  
CREATE                PROCEDURE dbo.spLocal_PPRGenealogy  
/* declare SP the varibles */  
--DECLARE   
 @LinesNeeded nvarchar(4000), --this is a string variable of all the pl_id's separated by |   
 @start  datetime,   --this is the report start  
 @end  datetime   --this is the report end  
AS  
/* set the SP variables */  
--SELECT @start = '6/11/06', @end = '6/12/06',@LinesNeeded = '44' --72  
/*Declare local varibles */  
DECLARE  
 @LinkStr   varchar(100),  --a lookup value for a call to GBDB.dbo.fnlocal_GlblParseInfo  
 @Now   datetime,   --the current date/time  
 @SearchString  NVARCHAR(4000), --this is the search string   
 @PartialString  NVARCHAR(4000), --this is the partial string  
 @Position   INT    --this is the position of the serch string     
  
/* Set Local Variables */  
SELECT @Now=getdate()  
  
/*the Lines Recordset */  
DECLARE @Lines TABLE(  
  PLID     int  
 )  
/*Rolls Running Recordset */  
DECLARE @Data TABLE(  
  [ID]     int identity,  
  [TedID]    int,  
  [Line]    varchar(100),  
  [Running Unit]   varchar(100),  
  [ULID]    varchar(100),  
  [Grand ULID]   varchar(100),  
  [PRID Running]   varchar(25),  
  [Parent PPR Status]  varchar(25),  
  [Grand PRID]   varchar(25),  
  [Grand PPR Status]  varchar(25),  
  [UWS Running]   varchar(25),  
  [Running StartTime]  datetime,  
  [Running EndTime]  datetime,  
  [PRID TimeStamp]  datetime,  
  [PRID PUID]   int,  
  [PRID Parent Type]  int,    --2=intermediate and 1=Papermachine  
  [GPRID PUID]   int,  
  [GPRID TimeStamp]  datetime  
  
 )  
/* Intermediate Rolls Units Record Set */   
DECLARE @IntUnits TABLE(  
  puid    int  
 )  
/* All Roll Units Record Set */  
DECLARE @PPRUnitsStart TABLE(  
  puid    int  
 )  
/* All Roll Units Record Set */  
DECLARE @PPRUnits TABLE(  
  puid    int  
 )  
/* Perfect Parent Roll Data Recordset */  
 DECLARE @PPRVariables TABLE(  
  PUID     int,  
  VarID    int,  
  Line     varchar(100),  
  Variable    varchar(50)  
 )  
  
 DECLARE @PPRData TABLE(  
  [ID]     int identity,  
  [Rolls ID]    int,  
  VarId    int,  
  [Parent Type]   int,  
  ResultOn    datetime,  
  ProdID    int,  
  Product    varchar(50),  
  Result    varchar(25),  
  [Lower Reject Limit]  varchar(25),  
  [Lower Warning Limit] varchar(25),  
  Target    varchar(25),  
  [Upper Warning Limit] varchar(25),  
  [Upper Reject Limit]  varchar(25)  
 )  
  
/* declare the variable tables */  
DECLARE @TPUID TABLE(  
  PUID  int,  
  RLVarID int  
  
 )  
/*Declare the stops RecordSet */  
DECLARE @TED TABLE(  
  [ID]     int identity,  
  TEDetID    int,  
  PUID     int,  
  [Line]    varchar(100),  
  [Production Unit]  varchar(100),  
  Product    varchar(100),  
  [Brand Code]   varchar(100),  
  SPUID    int,  
  Location    varchar(100),  
  [Event Type]   varchar(100),  
  StartTime    datetime,  
  EndTime    datetime,  
  [Effective Downtime]  real,  
  Fault     varchar(100),  
  R1     int,  
  [Failure Mode]   varchar(100),  
  R2     int,  
  [Failure Mode Cause]  varchar(100),  
  ERTDID    int,  
  Schedule    varchar(100),  
  Category    varchar(100),  
  Comment    varchar(5000)  
   
 )  
/* declare the start and end times by line recordset */  
DECLARE @Times TABLE(  
  [Line]    varchar(100),  
  plid     int,  
  StartTime    datetime,  
  EndTime    datetime  
 )  
/* Declare all the recordsets for the Cvtg test data */  
 DECLARE @BaseGroups TABLE(  
  [ID]    int identity,  
  Line    varchar(100),  
  [Production Group] varchar(100),  
  PUID    int,  
  PUGID   int  
 )  
  
 DECLARE @BaseVars TABLE(  
  [ID]    int identity,  
  [BGrpID]   int,  
  [VarID]   int,  
  [Variable]   varchar(100)  
 )  
 DECLARE @CvtgData TABLE (  
  [ID]     int identity,  
  [BVarID]    int,  
  [RollsID]    int,  
  [StartTime]   datetime,  
  [EndTime]    datetime,  
  [Product]    varchar(100),  
  [Brand Code]   varchar(100),  
  [ProdID]    int,  
  [Lower Reject Limit]  varchar(25),  
  [Lower Warning Limit] varchar(25),  
  Target    varchar(25),  
  [Upper Warning Limit] varchar(25),  
  [Upper Reject Limit]  varchar(25)  
 )  
BaseSetup:  
/* get the lines requested */  
 SELECT @SearchString = LTrim(RTrim(@LinesNeeded))  
 WHILE LEN(@SearchString) > 0  
  BEGIN  
   SELECT @Position = CHARINDEX('|', @SearchString)  
    IF  @Position = 0  
     SELECT @PartialString = RTRIM(@SearchString),@SearchString = ''  
    ELSE  
     SELECT @PartialString = RTRIM(SUBSTRING(@SearchString, 1, @Position - 1)),  
      @SearchString = LTRIM(RTRIM(SUBSTRING(@SearchString, (@Position + 1), Len(@SearchString))))  
     IF LEN(@PartialString) > 0  
      BEGIN  
       IF ISNUMERIC(@PartialString)=1  
        BEGIN  
         INSERT INTO @Lines(PLID)  
         SELECT  @PartialString  
        END  
       IF  ISNUMERIC(@PartialString) <>1  
        BEGIN  
         GOTO ReturnRecordSets  
        END   
      END  
   END  
/* fill @TPUID  with the base data*/  
INSERT INTO @TPUID(PUID)  
 SELECT pu_id   
  FROM dbo.prod_units pu   
   JOIN @Lines l ON l.plid = pu.pl_id  
 WHERE pu.pu_desc like '% Converter Reliability' or pu.pu_desc Like '% Rate Loss'  
DoStopsData:  
/*do stops data */  
/* set RLVarID of @TPUID */  
UPDATE d  
 SET RLVarID = v.var_id  
 FROM @TPUID d  
  LEFT JOIN dbo.variables v ON v.pu_id = d.puid and var_desc = 'Effective Downtime'  
/* Fill @TED with the base data */  
INSERT INTO @TED(TEDetID,PUID,SPUID,StartTime,EndTime,Fault,R1,R2,ERTDID,[Line])  
 SELECT ted.tedet_id,ted.pu_id,ted.source_pu_id,ted.start_time,coalesce(ted.End_Time, @Now),  
  tef.tefault_name,  
  ted.reason_level1,  
  ted.reason_level2,  
  pe.name_id,pl.pl_desc  
 FROM dbo.timed_event_details ted  
  INNER JOIN @TPUID d ON d.PUID = ted.pu_id  
  LEFT JOIN dbo.Timed_Event_Fault tef ON tef.tefault_id = ted.tefault_id  
  LEFT JOIN dbo.prod_events pe ON pe.pu_id = ted.source_pu_id and pe.event_type = 2  
  LEFT JOIN dbo.prod_units pu ON pu.pu_id = d.PUID  
  LEFT JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id  
 WHERE ted.start_time <= @End and (ted.end_time >= @Start or ted.end_time is null)  
/* Set comments in @TED */  
UPDATE @TED  
 SET Comment = rtrim(ltrim(convert(varchar(5000),WTC.Comment_Text)))  
 FROM dbo.Waste_n_Timed_Comments WTC   
 WHERE (TEDetId = WTC.WTC_Source_Id)   
    
/* set the correct PrimaryiD in @TED */  
UPDATE d1  
 SET [EVENT TYPE] = CASE   
  WHEN d2.TEDetID is null THEN 'Primary'  
  ELSE 'Extened'  
  END  
 FROM @TED d1  
  LEFT JOIN @TED d2 ON d1.PUID = d2.PUID and d1.StartTime = d2.EndTime    
/*update [Production Unit], Location, [Failure Mode] and [Failure Mocde Cause] of @TED */  
UPDATE d  
 SET [Failure Mode] =   
  CASE  
   WHEN d.R1 is not null THEN er1.event_reason_name  
   ELSE 'Not Edited'  
  END,  
 [Failure Mode Cause] =  
  CASE  
   WHEN d.R2 is not null THEN er2.event_reason_name  
   ELSE 'Not Edited'  
  END,  
 [Production Unit] = pu1.pu_desc,  
 Location = pu2.pu_desc  
 FROM @TED d  
  LEFT JOIN dbo.event_reasons er1 ON er1.event_reason_id = d.R1  
  LEFT JOIN dbo.event_reasons er2 ON er2.event_reason_id = d.R1  
  LEFT JOIN dbo.prod_units pu1 ON pu1.pu_id = d.PUID  
  LEFT JOIN dbo.prod_units pu2 ON pu2.pu_id = d.SPUID  
/* update the schedule and cateorgy of @TED */  
UPDATE d  
 SET Schedule = right(erc1.erc_desc,len(erc1.erc_desc)-9)  
  
 FROM @TED d  
  LEFT JOIN dbo.event_reason_tree_data ertd1 ON ertd1.tree_name_id = d.ERTDID and ertd1.Event_Reason_id = d.r2 and ertd1.event_reason_level =2   
  LEFT JOIN dbo.event_reason_category_data ercd1 ON ercd1.Event_Reason_Tree_data_id = ertd1.Event_Reason_Tree_data_id  
  LEFT JOIN dbo.event_reason_catagories erc1 ON erc1.erc_id = ercd1.erc_id  
 WHERE erc1.erc_desc like 'Schedule:%'  
  
UPDATE d  
 SET Category = right(erc1.erc_desc,len(erc1.erc_desc)-9)  
 FROM @TED d  
  LEFT JOIN dbo.event_reason_tree_data ertd1 ON ertd1.tree_name_id = d.ERTDID and ertd1.Event_Reason_id = d.r2 and ertd1.event_reason_level =2   
  LEFT JOIN dbo.event_reason_category_data ercd1 ON ercd1.Event_Reason_Tree_data_id = ertd1.Event_Reason_Tree_data_id  
  LEFT JOIN dbo.event_reason_catagories erc1 ON erc1.erc_id = ercd1.erc_id  
 WHERE erc1.erc_desc like 'Category:%'  
/* Set the Effective downtime of @TED */  
 /*When a rate loss event */  
  UPDATE ted  
   SET [Effective Downtime] = t.result  
   FROM @TED ted  
    LEFT JOIN @TPUID tp ON tp.puid= ted.puid  
    LEFT JOIN dbo.tests t ON t.var_id = tp.RLVarID and t.result_on = ted.[StartTime]  
 /*When not a Rate loss event */  
  UPDATE ted  
   SET [Effective Downtime]= (convert(float(8),ted.[EndTime])-convert(float(8),ted.[StartTime]))*1140  
  FROM @TED ted  
   LEFT JOIN @TPUID tp ON tp.puid= ted.puid  
  WHERE tp.RLVarID is null  
/* Set the Product of TED */  
UPDATE ted  
 SET product = p.prod_desc,  
  [Brand Code] = p.prod_code  
 FROM @TED ted  
  LEFT JOIN dbo.production_Starts ps ON ps.pu_id = ted.puid  
  LEFT JOIN dbo.products p ON p.prod_id = ps.prod_id  
 WHERE ps.prod_id >1 and ps.start_time<= ted.StartTime and (ps.end_time >= ted.StartTime or ps.end_time is null)  
DoRollsData:  
/*Get the Roll Data */  
INSERT INTO @Times(Line,StartTime,EndTime)  
 SELECT Line,min(StartTime),max(EndTime)  
  FROM @TED  
  GROUP BY Line  
UPDATE t  
 SET plid= pl.pl_id  
 FROM @Times t  
  LEFT JOIN dbo.prod_lines pl ON pl.pl_desc = t.[Line]  
/*insert into @data */  
INSERT INTO @Data(  
  [Line],  
  [Running Unit],  
  [ULID],  
  [PRID Running],  
  [UWS Running],  
  [Running StartTime],  
  [Running EndTime],  
  [PRID TimeStamp],  
  [PRID PUID]  
 )  
SELECT --pl.pl_desc,  
 times.[Line],pu.pu_desc,e.event_num,  
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'No Assigned PRID'  
   END,  
  CASE  
   WHEN t1.result is not null then t1.result  
   ELSE 'No UWS Assigned'  
   END,   
  eh.entry_on,   
  e.entry_on,  
  e1.timestamp,  
  e1.pu_id  
             FROM dbo.events e   
                        LEFT JOIN dbo.event_history eh ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu ON pu.pu_id = e.pu_id   
      LEFT JOIN @Times times ON times.plid = pu.pl_id  
                        LEFT JOIN dbo.events e1 ON e1.event_id = e.source_event   
                        LEFT JOIN dbo.prod_units pu1 ON pu1.pu_id = e1.pu_id    
                        LEFT JOIN dbo.variables v ON v.pu_id = e1.pu_id and v.var_desc = 'PRID'   
                        LEFT JOIN dbo.tests t ON t.var_id = v.var_id and t.result_on = e1.timestamp   
      LEFT JOIN dbo.variables v1 ON v1.pu_id = e.pu_id and v1.var_desc = 'Unwind Stand'  
      LEFT JOIN dbo.tests t1 ON t1.var_id = v1.var_id and t1.result_on = e.timestamp  
           WHERE (times.StartTime<=e.timestamp  and e.timestamp <= times.EndTime)   
                                    and ps2.prodstatus_desc<> 'Inventory'   
                                    and pu.pu_desc like '% Converter Production'   
                                    and ps2.prodstatus_desc = 'Running'   
            ORDER BY pu.pu_desc,e.event_id,eh.entry_on   
  
/* update [PRID Running], [PRID PUID] and [PRID TimeStamp]if the ULID of @Data has a - in it */  
UPDATE d  
 SET [PRID Running] =t.result,  
  [PRID TimeStamp] = e.timestamp,  
  [PRID PUID] = e.pu_id  
 FROM @Data d  
  LEFT JOIN dbo.events e ON e.event_num =left(d.ulid,20)  
                    LEFT JOIN dbo.variables v ON v.pu_id = e.pu_id and v.var_desc = 'PRID'   
                    LEFT JOIN dbo.tests t ON t.var_id = v.var_id and t.result_on = e.timestamp   
  LEFT JOIN dbo.prod_units pu ON pu.pu_id = e.pu_id  
 WHERE pu.pu_desc LIKE '% Rolls' and [PRID Running] = 'No Assigned PRID'  
  
/* Update @Data set [PRID ParentType] */  
/* fill @IntUnits  THis is all the Sites Intermediate Roll Units */  
SELECT @LinkStr= 'RollsUnit='  
 INSERT INTO @IntUnits(puid)  
 SELECT pu.pu_id  
  FROM dbo.prod_units pu  
 WHERE pu.pu_id > 0 and GBDB.dbo.fnlocal_GlblParseInfo(pu.extended_info,@LinkStr) = 'Intr'  
  
 UPDATE d  
  SET [PRID Parent Type] = CASE  
   WHEN d.[PRID PUID] = iu.puid THEN 2  
   ELSE 1  
   END  
  FROM @data d  
   LEFT JOIN @IntUnits iu ON iu.puid = d.[PRID PUID]  
/* UPDATE [Grand ULID], [Grand PRID],[GPRID PUID] and [GPRID TimeStamp] */  
Update d  
 SET [Grand PRID] = t1.result  
 FROM @Data d  
  JOIN dbo.tests t1 ON t1.result_on = d.[PRID Timestamp] and d.[PRID Parent Type] =2  
  JOIN dbo.variables v1 ON v1.var_id = t1.var_id and v1.pu_id = d.[PRID PUID]   
 WHERE v1.var_desc in( 'Input Roll ID' , 'Input PRID')  
UPDATE d  
 SET [GPRID PUID]= pu.pu_id  
 FROM @Data d  
  LEFT JOIN dbo.prod_units pu ON pu.pu_desc like '%' + left([Grand PRID],2) + ' Rolls' and d.[PRID Parent Type] =2  
Update d  
 SET [GPRID TimeStamp] = t.result_on  
 FROM @Data d  
  LEFT JOIN dbo.variables v ON v.pu_id = d.[GPRID PUID] and d.[PRID Parent Type] = 2 and v.var_id >0  
  LEFT JOIN dbo.tests t ON t.var_id = v.var_id  
 WHERE v.var_desc = 'PRID' and t.result = d.[Grand PRID]  
Update d  
 SET [Grand ULID] = e.event_num  
 FROM @Data d  
  LEFT JOIN dbo.events e ON e.pu_id = d.[GPRID PUID] and e.timestamp = d.[GPRID TimeStamp] and d.[PRID Parent Type] = 2  
/* set the Parent PPR Status and the Grand PPR Status of @Data */  
 Update d  
  SET [Parent PPR Status]= t.result  
 FROM @Data d  
  LEFT JOIN dbo.variables v ON v.pu_id = d.[PRID PUID] and v.var_desc = 'Perfect Parent Roll Status'  
  LEFT JOIN dbo.tests t ON t.var_id = v.var_id  
 WHERE t.result_on = d.[PRID TimeStamp]  
 Update d  
  SET [Grand PPR Status]= t.result  
 FROM @Data d  
  LEFT JOIN dbo.variables v ON v.pu_id = d.[GPRID PUID] and v.var_desc = 'Perfect Parent Roll Status' and d.[PRID Parent Type] = 2  
  LEFT JOIN dbo.tests t ON t.var_id = v.var_id  
 WHERE t.result_on = d.[GPRID TimeStamp]  
  
/* update TedID of @Data */  
 UPDATE d  
  SET [TedID] =ted.[ID]  
 FROM @Data d  
  LEFT JOIN @TED ted ON ted.line = d.line  
 WHERE ted.[EndTime] >= d.[Running StartTime] and (d.[Running EndTime] >= ted.[StartTime])  
   and ted.[Production Unit] not like '% Rate Loss'  
DoPmkgIntrData:  
/* insert all the DISTINCT [PRID PUID] and [GPRID PUID] into @PPRUnits */  
INSERT INTO @PPRUnitsStart(puid)  
 SELECT DISTINCT  d.[PRID PUID]  
  FROM @Data d  
  WHERE d.[PRID PUID] is not null  
INSERT INTO @PPRUnitsStart(puid)  
 SELECT DISTINCT  d.[GPRID PUID]  
  FROM @Data d   
  WHERE d.[PRID Parent Type] =2 and d.[GPRID PUID] is not null  
INSERT INTO @PPRUnits(PUID)  
 SELECT DISTINCT puid  
  FROM @PPRUnitsStart  
  
/* get all the PPR Variables */  
INSERT INTO @PPRVariables(PUID,VarID,Line,Variable)  
SELECT pu.pu_id,v.var_id,pl.pl_desc,v.var_desc  
 FROM [dbo].Calculation_Instance_Dependencies CID  
  JOIN dbo.variables v ON v.var_id = cid.var_id  
  JOIN dbo.variables v1 ON v1.var_id = cid.result_var_id  
  JOIN @PPRUnits ppru ON ppru.puid = v.pu_id  
  LEFT JOIN dbo.prod_units pu ON pu.pu_id = ppru.puid  
  LEFT JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id  
 WHERE cid.Calc_Dependency_NotActive = 0  
  and (v.var_desc <> 'Recalculate PPR')  
  and v1.var_desc = 'Perfect Parent Roll Status'  
INSERT INTO @PPRVariables(PUID,VarID,LINE,Variable)  
SELECT pu.pu_id,v.var_id,pl.pl_desc,v.var_desc  
 FROM dbo.variables v  
  LEFT JOIN @PPRUnits ppru ON ppru.puid = v.pu_id  
  LEFT JOIN dbo.prod_units pu ON pu.pu_id = ppru.puid  
  LEFT JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id  
 WHERE var_desc = 'Perfect Parent Roll Status'  
  
/*get all the timestamps for all the variables in question */  
INSERT INTO @PPRData(VarID,ResultOn,[Parent Type],[Rolls ID])  
 SELECT pprv.VarID,d.[PRID Timestamp],d.[PRID Parent Type],d.[ID]  
  FROM @PPRVariables pprv  
   LEFT JOIN @Data d ON d.[PRID PUID] = pprv.PUID -- and d.[PRID Parent Type] = 1  
INSERT INTO @PPRData(VarID,ResultOn,[Parent Type],[Rolls ID])  
 SELECT pprv.VarID,d.[GPRID Timestamp],d.[PRID Parent Type],d.[ID]  
  FROM @PPRVariables pprv  
   LEFT JOIN @Data d ON d.[GPRID PUID] = pprv.PUID and d.[PRID Parent Type] = 2  
/* Update ProdID and Product of @PPRData */  
UPDATE d  
 SET ProdID = p.prod_id,  
  Product = p.prod_desc  
 FROM @PPRData d  
  LEFT JOIN @PPRVariables pprv ON pprv.VarID = d.VarID  
  LEFT JOIN @Data da ON da.[PRID PUID] = pprv.PUID and da.[PRID Parent Type] = 1  
  LEFT JOIN dbo.production_starts ps ON ps.pu_id = pprv.PUID  
  LEFT JOIN dbo.products p ON p.prod_id = ps.prod_id  
 WHERE ps.Start_Time <= d.ResultOn and (ps.end_time >= d.ResultOn or ps.end_time IS NULL)  
  
UPDATE d  
 SET ProdID = p.prod_id,  
  Product = p.prod_desc  
 FROM @PPRData d  
  LEFT JOIN @PPRVariables pprv ON pprv.VarID = d.VarID  
  LEFT JOIN @Data da ON da.[GPRID PUID] = pprv.PUID and da.[PRID Parent Type] = 2  
  LEFT JOIN dbo.production_starts ps ON ps.pu_id = pprv.PUID  
  LEFT JOIN dbo.products p ON p.prod_id = ps.prod_id  
 WHERE ps.Start_Time <= d.ResultOn and (ps.end_time >= d.ResultOn or ps.end_time IS NULL)  
/* get the result for @PPRData */  
UPDATE p  
 SET Result = t.result  
 FROM @PPRData p  
  LEFT JOIN dbo.tests t ON t.var_id = p.VarID and t.result_on = p.ResultOn  
DELETE FROM @PPRData WHERE result is null  
  
/* get the specs for all the dta left in @PPRData */  
UPDATE d  
 SET [Lower Reject Limit] = vs.L_Reject,  
  [Lower Warning Limit] = vs.L_Warning,  
  [Target] = vs.Target,  
  [Upper Warning Limit] =vs.U_Warning,  
  [Upper Reject Limit] = vs.U_Reject  
 FROM @PPRData d  
  LEFT JOIN dbo.var_specs vs ON vs.var_id = d.VarID and vs.prod_id = d.ProdID  
 WHERE vs.effective_date <= d.ResultOn and (vs.expiration_date >= d.ResultOn or vs.expiration_date is null)  
DoCvtgData:  
/* get the converting variables */  
/* set @LinkStr */  
 SELECT @LinkStr = 'PPRGRP='  
/* Get all the Production Groups required */  
 INSERT INTO @BaseGroups(LINE,[Production Group],PUID,PUGID)  
 SELECT pl.pl_desc,pug.pug_desc,pu.pu_id,pug.pug_id  
  FROM dbo.pu_groups pug  
   LEFT JOIN dbo.prod_units pu ON pu.pu_id = pug.pu_id  
   LEFT JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id  
   JOIN @Lines l ON l.plid = pl.pl_id  
  WHERE GBDB.dbo.fnlocal_GlblParseInfo(pug.external_link,@LinkStr) = 'Yes'  
/* Get all the Varialbes */  
 INSERT INTO @BaseVars([BGrpID],[VarID],[Variable])  
 SELECT b.[ID],v.var_id,v.var_desc  
  FROM dbo.variables v  
   JOIN @BaseGroups b ON b.pugid = v.pug_id  
  WHERE (v.var_desc not like '% PLC%' and v.var_desc not like '%:PLC%') and v.var_desc not like '% INT' and v.var_desc not like '%Initials%'  
  
/* Get all the Rolls to get data for  and insert into @CvtgData*/  
 INSERT INTO @CvtgData ([BVarID],[RollsID],[StartTime],[EndTime])  
 SELECT bv.[ID],d.[ID],d.[Running StartTime],d.[Running EndTime]  
  FROM @Data d  
   LEFT JOIN @BaseGroups bg ON bg.[Line] = d.[Line]  
   LEFT JOIN @BaseVars bv ON bv.[BGrpID] = bg.[ID]  
/* Update prodid and product of @CvtgData */  
 UPDATE c  
  SET [Brand Code] = p.prod_code,  
   [Product] = p.prod_desc,  
   [ProdID] = p.prod_id  
  FROM @CvtgData c  
   LEFT JOIN @BaseVars bv ON bv.[ID] = c.[BVarID]  
   LEFT JOIN @BaseGroups bg ON bg.[ID] = bv.[BGrpID]  
   LEFT JOIN dbo.production_starts ps ON ps.pu_id = bg.puid  
   LEFT JOIN dbo.products p ON p.prod_id = ps.prod_id  
  WHERE ps.prod_id >1 and ps.start_time<= c.StartTime and (ps.end_time >= c.StartTime or ps.end_time is null)  
/*Update Result of @CvtgData */  
 UPDATE c  
  SET [Lower Reject Limit] = vs.L_Reject,  
   [Lower Warning Limit] = vs.L_Warning,  
   [Target] = vs.Target,  
   [Upper Warning Limit] =vs.U_Warning,  
   [Upper Reject Limit] = vs.U_Reject  
  FROM @CvtgData c  
   LEFT JOIN @BaseVars bv ON bv.[ID] = c.[BVarID]  
   LEFT JOIN dbo.var_specs vs ON vs.var_id = bv.[VarID] and vs.prod_id = c.ProdID  
  WHERE vs.effective_date <= c.StartTime and (vs.expiration_date >= c.StartTime or vs.expiration_date is null)  
ReturnRecordSets:  
/* return the Rolls Recordset */  
 SELECT [ID],[TedID],[Line],[ULID],[Grand ULID],[PRID Running],[Parent PPR Status],  
  [Grand PRID],[Grand PPR Status],[UWS Running],[Running StartTime],[Running EndTime]  
 FROM @Data  
/* return the test data recordset */  
 SELECT d.[ID],d.[Rolls ID],pprv.[Variable],d.Product,d.ResultOn,  
   d.Result,d.[Lower Reject Limit],d.[Lower Warning Limit],d.Target,  
   d.[Upper Warning Limit],d.[Upper Reject Limit]  
 FROM @PPRData d  
  LEFT JOIN @PPRVariables pprv ON pprv.VarID = d.VarID  
/*return the stops recordset */  
 SELECT d.[ID],d.[Line],d.[Production Unit],d.[Product],d.[Brand Code],  
   d.Location,d.[Event Type],d.StartTime,d.EndTime,d.[Effective Downtime],d.Fault,  
   d.[Failure Mode],d.[Failure Mode Cause],d.Schedule,  
   d.Category,d.Comment  
  FROM @TED d  
/*Return the @CvtgData RecordSet  with the average of all the int and float data*/  
 SELECT c.[RollsID],bv.[Variable],c.[Product],c.[Brand Code],convert(varchar(10),avg(convert(real,t.result))) as [Result],c.[Lower Reject Limit],c.[Lower Warning Limit],c.Target,  
   c.[Upper Warning Limit],c.[Upper Reject Limit]  
  FROM dbo.tests t  
   LEFT JOIN dbo.variables v oN v.var_id = t.var_id  
   JOIN @BaseVars bv ON bv.[VarID] = v.var_id   
   JOIN @CvtgData c ON c.[BVarid] = bv.[ID]  
  WHERE (t.Result_on >= c.[StartTime] and t.Result_on <= c.[EndTime])  
   and (v.data_type_id = 1 or v.data_type_id = 2)  
  GROUP BY c.[RollsID],bv.[Variable],c.[Product],c.[Brand Code],c.[Lower Reject Limit],c.[Lower Warning Limit],c.Target,  
   c.[Upper Warning Limit],c.[Upper Reject Limit]  
  ORDER by c.[RollsID],bv.[Variable]  
  
  
  
  
  
SET QUOTED_IDENTIFIER OFF   
