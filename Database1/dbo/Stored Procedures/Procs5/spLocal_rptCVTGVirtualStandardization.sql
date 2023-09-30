  /*  
Stored Procedure: dbo.spLocal_rptCVTGVirtualStandardization  
Author:   Fran Osorno  
Date Created:  July 18, 2006  
  
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
   [ID],[Line],[ULID],[Grand ULID],[PRID Running],[Grand PRID],[UWS Running],  
    [Running StartTime], [Running EndTime]  
  2. Cvtg Test Data for when rolls where run  
   c.[RollsID],bv.[Variable],avg(convert(real,t.result)),c.[Lower Reject Limit],c.[Lower Warning Limit],c.Target,  
    c.[Upper Warning Limit],c.[Upper Reject Limit]  
  
This code calls the following functions  
 CALLS: GBDB.dbo.fnlocal_GlblParseInfo  
  
Change Date  Who  What  
===========  ====  =====  
07/18/06   FGO  Created procedure.  
08/25/06   fgo  Added Line to all recordsets  
03/15/07   FGO  updated the final query to remove nulls and update the avg statement to handle a variable of length 25  
03/17/07   FGO  added EngUnits to the BaseVariabels table the the final Variables extract selection  
17-MAY-2007  FLD  1. Changed some '<=' to just '<' so that data is not duplicated by being picked up at both  
         the start and end times.  
        2. Added 'WITH (NOLOCK)' to all Proficy table references.  
*/  
CREATE                PROCEDURE dbo.spLocal_rptCVTGVirtualStandardization  
/* declare SP the varibles */  
--DECLARE   
 @LinesNeeded nvarchar(4000), --this is a string variable of all the pl_id's separated by |   
 @start  datetime,   --this is the report start  
 @end  datetime   --this is the report end  
AS  
/* set the SP variables */  
--SELECT @start = '08/25/06 07:00', @end = '8/25/06 10:00',@LinesNeeded = '74' --72  
--SELECT @start = '3/5/07 06:00:00', @end = '3/6/07 06:00:00',@LinesNeeded = '262' --72  
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
  [BGrpID]  int,  
  [VarID]   int,  
  [Variable]  varchar(100),  
  [EngUnits]  varchar(50)  --this is the Eng_Units from dbo.variables  
  
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
DoRollsData:  
/*Get the Roll Data */  
INSERT INTO @Times(Line,PLID,StartTime,EndTime)  
 SELECT pl.pl_desc,l.PLID,@Start,@End  
  FROM @Lines l  
   LEFT JOIN dbo.prod_lines pl WITH (NOLOCK) ON pl.pl_id = l.PLID  
  GROUP BY pl.pl_Desc, l.PLID  
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
             FROM dbo.events e WITH (NOLOCK)  
              LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id   
  LEFT JOIN @Times times ON times.plid = pu.pl_id  
                LEFT JOIN dbo.events e1 WITH (NOLOCK) ON e1.event_id = e.source_event   
                LEFT JOIN dbo.prod_units pu1 WITH (NOLOCK) ON pu1.pu_id = e1.pu_id    
                LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e1.pu_id and v.var_desc = 'PRID'   
                LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e1.timestamp   
  LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.pu_id and v1.var_desc = 'Unwind Stand'  
  LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp  
           WHERE (times.StartTime<=e.timestamp  and e.timestamp < times.EndTime)   
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
  LEFT JOIN dbo.events e WITH (NOLOCK) ON e.event_num =left(d.ulid,20)  
                    LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.pu_id and v.var_desc = 'PRID'   
                    LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
  LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
 WHERE pu.pu_desc LIKE '% Rolls' and [PRID Running] = 'No Assigned PRID'  
  
/* Update @Data set [PRID ParentType] */  
/* fill @IntUnits  THis is all the Sites Intermediate Roll Units */  
SELECT @LinkStr= 'RollsUnit='  
 INSERT INTO @IntUnits(puid)  
 SELECT pu.pu_id  
  FROM dbo.prod_units pu WITH (NOLOCK)  
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
  JOIN dbo.tests t1 WITH (NOLOCK) ON t1.result_on = d.[PRID Timestamp] and d.[PRID Parent Type] =2  
  JOIN dbo.variables v1 WITH (NOLOCK) ON v1.var_id = t1.var_id and v1.pu_id = d.[PRID PUID]   
 WHERE v1.var_desc in( 'Input Roll ID' , 'Input PRID')  
UPDATE d  
 SET [GPRID PUID]= pu.pu_id  
 FROM @Data d  
  LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_desc like '%' + left([Grand PRID],2) + ' Rolls' and d.[PRID Parent Type] =2  
Update d  
 SET [GPRID TimeStamp] = t.result_on  
 FROM @Data d  
  LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = d.[GPRID PUID] and d.[PRID Parent Type] = 2 and v.var_id >0  
  LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id  
 WHERE v.var_desc = 'PRID' and t.result = d.[Grand PRID]  
Update d  
 SET [Grand ULID] = e.event_num  
 FROM @Data d  
  LEFT JOIN dbo.events e WITH (NOLOCK) ON e.pu_id = d.[GPRID PUID] and e.timestamp = d.[GPRID TimeStamp] and d.[PRID Parent Type] = 2  
/* set the Parent PPR Status and the Grand PPR Status of @Data */  
 Update d  
  SET [Parent PPR Status]= t.result  
 FROM @Data d  
  LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = d.[PRID PUID] and v.var_desc = 'Perfect Parent Roll Status'  
  LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id  
 WHERE t.result_on = d.[PRID TimeStamp]  
 Update d  
  SET [Grand PPR Status]= t.result  
 FROM @Data d  
  LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = d.[GPRID PUID] and v.var_desc = 'Perfect Parent Roll Status' and d.[PRID Parent Type] = 2  
  LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id  
 WHERE t.result_on = d.[GPRID TimeStamp]  
  
DoCvtgData:  
/* get the converting variables */  
/* set @LinkStr */  
 SELECT @LinkStr = 'PPRGRP='  
/* Get all the Production Groups required */  
 INSERT INTO @BaseGroups(LINE,[Production Group],PUID,PUGID)  
 SELECT pl.pl_desc,pug.pug_desc,pu.pu_id,pug.pug_id  
  FROM dbo.pu_groups pug WITH (NOLOCK)  
   LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = pug.pu_id  
   LEFT JOIN dbo.prod_lines pl WITH (NOLOCK) ON pl.pl_id = pu.pl_id  
   JOIN @Lines l ON l.plid = pl.pl_id  
  WHERE GBDB.dbo.fnlocal_GlblParseInfo(pug.external_link,@LinkStr) = 'Yes'  
/* Get all the Varialbes */  
 INSERT INTO @BaseVars([BGrpID],[VarID],[Variable],[EngUnits])  
 SELECT b.[ID],v.var_id,v.var_desc,  
  CASE   
   WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
   ELSE v.eng_units  
  END  
  FROM dbo.variables v WITH (NOLOCK)  
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
   LEFT JOIN dbo.production_starts ps WITH (NOLOCK) ON ps.pu_id = bg.puid  
   LEFT JOIN dbo.products p WITH (NOLOCK) ON p.prod_id = ps.prod_id  
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
   LEFT JOIN dbo.var_specs vs WITH (NOLOCK) ON vs.var_id = bv.[VarID] and vs.prod_id = c.ProdID  
  WHERE vs.effective_date <= c.StartTime and (vs.expiration_date >= c.StartTime or vs.expiration_date is null)  
ReturnRecordSets:  
/* return the Rolls Recordset */  
 SELECT [ID],[Line],[ULID],[Grand ULID],[PRID Running],  
  left([PRID Running],2)+right([PRID Running],4)+right(left([PRID Running],3),1)+right(left([PRID Running],6),3) as [PTID],  
  [Parent PPR Status],[Grand PRID],  
  left([Grand PRID],2)+right([Grand PRID],4)+right(left([Grand PRID],3),1)+right(left([Grand PRID],6),3) as [GTID],  
  [Grand PPR Status],[UWS Running],[Running StartTime],[Running EndTime]  
 FROM @Data  
/*Return the @CvtgData RecordSet  with the average of all the int and float data*/  
 SELECT d.Line,c.[RollsID],bv.[Variable],bv.[EngUnits],c.[Product],c.[Brand Code],  
   convert(varchar(25),avg(convert(real,t.result))) as [Result],  
   c.[Lower Reject Limit],c.[Lower Warning Limit],c.Target,  
   c.[Upper Warning Limit],c.[Upper Reject Limit]  
  FROM dbo.tests t WITH (NOLOCK)  
   LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.var_id = t.var_id  
   JOIN @BaseVars bv ON bv.[VarID] = v.var_id   
   JOIN @CvtgData c ON c.[BVarid] = bv.[ID]  
   JOIN @Data d ON d.[ID] = c.[RollsID]  
  WHERE (t.Result_on >= c.[StartTime] and t.Result_on < c.[EndTime])  
   and (v.data_type_id = 1 or v.data_type_id = 2) and t.result is not null  
  GROUP BY d.line,c.[RollsID],bv.[Variable],bv.[EngUnits],c.[Product],c.[Brand Code],c.[Lower Reject Limit],c.[Lower Warning Limit],c.Target,  
   c.[Upper Warning Limit],c.[Upper Reject Limit]  
  ORDER by d.line,c.[RollsID],bv.[Variable]  
  
SET QUOTED_IDENTIFIER OFF   
