   /*  
Stored Procedure: dbo.spLocal_rptPMKGVirtualStandardization  
Author:   Fran Osorno  
Date Created:  July 17, 2006  
  
Description:  
=========  
      
  
Change Date  Who   What  
===========  ====   =====  
July 17, 2006  FGO  Created procedure  
July 21, 20066  FGO  Corrected the specs for Quality, Added A Variable Type for ease of displaying and a Prodcut of Materials Constant for all Materials Contants  
Aug 25, 2006  FGO  added Line to all data sets  
Dec 13, 2006  FGO  updated to handle version  4.x use of the event history table  
Jan 4, 2006   FGO  updated the code to handle varchar data in the test table  
         Added a variable table @BaseData to handle this need  
Feb 16, 2006  FGO  corrected the insert of the result into @Materials  
March 07,2007  FGO  Added the Ability to get Turnover Snap Data from the Turnover Quality Production Unit  
March 17,2007  FGO  Updated the query for Turnover Snap data and for the clothing data when no removed date is found  
17-MAY-2007   FLD  1. Changed some '<=' to just '<' so that data is not duplicated by being picked up at both  
         the start and end times.  
         2. Added 'WITH (NOLOCK)' to all Proficy table references.  
Aug 03, 2009  VMK  Added Prod Group Turnover Snap Process Variables section to retrieve variables.  
  
*/  
CREATE      PROCEDURE [dbo].[spLocal_rptPMKGVirtualStandardization]  
  
-- DECLARE   
 @LinesNeeded nvarchar(4000), --this is a string variable of all the pl_id's separated by |   
 @start  datetime,   --this is the report start  
 @end  datetime   --this is the report end  
AS  
/* set the SP variables */  
-- SELECT @start = '8/1/09 05:00:00', @end = '8/2/09 08:00:00',@LinesNeeded = '28' --72  
--SELECT @start = '12/12/06 08:00:00', @end = '12/12/06 11:00:00',@LinesNeeded = '20' --72  
--pc2x 23  
--pc1x 27  
--SELECT @start = '1/2/07 05:00:00', @end = '1/2/07 09:00:00',@LinesNeeded = '154' --72  
--SELECT @start = '1/3/07 00:00:00', @end = '1/4/07 00:00:00',@LinesNeeded = '168' --72  
--SELECT @start = '3/5/07 13:50:41', @end = '3/5/07 16:50:41',@LinesNeeded = '109' --72  
/*Declare local varibles */  
DECLARE  
 @LinkStr   varchar(100),  --a lookup value for a call to GBDB.dbo.fnlocal_GlblParseInfo  
 @Now    datetime,   --the current date/time  
 @SearchString  nvarchar(4000), --this is the search string   
 @PartialString  nvarchar(4000), --this is the partial string  
 @Position   int    --this is the position of the serch string     
  
/* Set Local Variables */  
SELECT @Now=getdate()  
  
/*the Lines Recordset */  
DECLARE @Lines TABLE(  
  PLID   int  
 )  
/*the MCharDesc recordset */  
DECLARE @MCharDesc TABLE (  
  CharDesc  varchar(25)  
 )  
/* the Units Recordset */  
DECLARE @Units TABLE(  
  PUID   int,   --this is the pu_id   
  Type   int,   --1= production, 2= Turnover Quality, 3= Centerlines, 4 = Materials  
  Line   varchar(4) --thi s is the left(pu_desc,4) for the line description  
 )  
/*Turnover Events Recordset */  
DECLARE @TOEvents TABLE(  
  TOID    int identity, --this is the ID of this table  
  TID    varchar(50), --this is the event_num of dbo.events  
  EventID   int,   --this is the event_id of dbo.events  
  ProdPUID   int,   --this is the pu_id of the production unit of the turnover from @Units  
  ClinPUID   int,   --this is the pu_id of the centerline unit for the line from @Units  
  Line    varchar(4), --this is the line description from @Units  
  StartTime   datetime,  --this is the start of the turnover  
  EndTime   datetime,  --this is the end of the turnover from dbo.events timestamp  
  TOWeight   real,   --this is the weight of the turnover fromthe variable Turnover Weight Official  
  ProdID   int,   --this is the prod_id from dbo.products of the product on the line  
  Product   varchar(50), --this is the prod_desc from dbo.products of the product on the line  
  [FormingWire ID] varchar(25), --this is the Forming Wire ID form @FormingWire  
  [BackingWire ID] varchar(25), --this is the Backing Wire ID form @BackingWire  
  [Belt ID]   varchar(25) --this is the BeltID from @Belts  
 )  
/* Turnover StartTime Rescordset */  
DECLARE @TOEStartTime TABLE(  
  TOID   int,    --this is the ID from @TOEvents  
  StarTtime  datetime   --this is the EndTime from @TOEvents  
 )  
/*Variable Recordset */  
DECLARE @VarsToGet TABLE(  
  VID    int identity,  --this is the ID of this table  
  VarID   int,    --this is the var_id from dbo.variables  
  Variable   varchar(50),  --this is the var_desc from dbo.variables  
  [Variable Type]  varchar(25),  --Quality, Centerline, Produciton, Materials  
  EngUnits   varchar(50),  --this is the Eng_Units from dbo.variables  
  PUID    int,    --this is the PUID from @Units  
  Line    varchar(4),  --this is the left(pu_desc,4) for the line description  
  Type    int,    --this is the unit type from @Units  
  SpecID   int,    --this is the spec_id from dbo.variables  
  DataSource  varchar(25)  --this is the ds_desc from dbo.data_source  
  
 )  
/*Data Recordset */  
DECLARE @Data Table(  
  TOID     int,    --this is the TOID from @TOEvents  
  VID     int,    --this is the VID from @VarsToGet  
  result    real,    --this is the result of the data  
  ProdID    int,    --this is the prod_id form dbo.products  
  [Lower Reject Limit]  varchar(25),  --this is the LRL form dbo.var_specs  
  [Lower Warning Limit] varchar(25),  --this is the LWL from dbo.var_specs  
  Target    varchar(25),  --this is the target from dbo.var_specs  
  [Upper Warning Limit] varchar(25),  --this is the UWL from dbo.var_specs  
  [Upper Reject Limit]  varchar(25)  --this is the URL from dbo.var_specs  
  
    
 )  
/*Data Recordset */  
DECLARE @BaseData Table(  
  TOID     int,    --this is the TOID from @TOEvents  
  VID     int,    --this is the VID from @VarsToGet  
  result    real    --this is the result of the data  
 )  
    
/*Materials Recordset */  
DECLARE @Materials Table(  
  VID     int,    --this is the VID from @VarsToGet  
  Start     datetime,   --this the result_on from dbo.tests  
  [END]    datetime,   --this is the expiration_date of active_specs for the targets  
  result    real,    --this is the result of the data  
  ProdID    int,    --this is the prod_id form dbo.products  
  [Lower Reject Limit]  varchar(25),  --this is the LRL form dbo.var_specs  
  [Lower Warning Limit] varchar(25),  --this is the LWL from dbo.var_specs  
  Target    varchar(25),  --this is the target from dbo.var_specs  
  [Upper Warning Limit] varchar(25),  --this is the UWL from dbo.var_specs  
  [Upper Reject Limit]  varchar(25)  --this is the URL from dbo.var_specs  
  
    
 )  
  
/*Cleaning Blade Record set */  
DECLARE @CleaningBlades TABLE(  
  [Blade Change ID]  varchar(50), --this is the event_num form dbo.events  
  [Timestamp]   datetime,  --this is the timestamp from dbo.events  
  [PUID]    int,   --this is the pu_id from dbo.events  
  [TID]    varchar(50), --this is the TID from dbo.tests  
  [Line]    varchar(4), --this is the left(pu_desc,4) for the line description  
  [Blade Life]   varchar(50), --this is the Blade Life from dbo.tests  
  [Blade Change Duration] varchar(50), --this is the Blade Change Duration from dbo.tests  
  [Blade Change Cause] varchar(50), --this is the Blade Change Cause from dbo.tests  
  [Blade Change Reason] varchar(50), --this is the Blade Chagne Reason from dbo.tests  
  [Blade Angle]   varchar(50), --this is the Blade Angle from dbo.tests  
  [Blade Free Height]  varchar(50), --this is the Blade Free Height from dbo.tests  
  [Blade Height]   varchar(50), --this is the Blade Height from dbo.tests  
  [Blade Length]   varchar(50) --this is the Blade Length from dbo.tests  
 )  
/*Creping Blade Recordset */  
DECLARE @CrepingBlades TABLE(  
  [Blade Change ID]  varchar(50), --this is the event_num from dbo.events  
  [Timestamp]   datetime,  --this is the timestamp from dbo.events  
  [PUID]    int,   --this is the pu_id from dbo.events  
  [TID]    varchar(50), --this is the TID from dbo.tests  
  [Line]    varchar(4), --this is the left(pu_desc,4) for the line description  
  [Blade Life]   varchar(50), --this is the Blade Life from dbo.tests  
  [Blade Change Duration] varchar(50), --this is the Blade Change Duration from dbo.tests  
  [Blade Change Cause] varchar(50), --this is the Blade Change Cause from dbo.tests  
  [Blade Change Reason] varchar(50), --this is the Blade Chagne Reason from dbo.tests  
  [Blade Angle]   varchar(50), --this is the Blade Angle from dbo.tests  
  [Blade Free Height]  varchar(50), --this is the Blade Free Height from dbo.tests  
  [Blade Height]   varchar(50), --this is the Blade Height from dbo.tests  
  [Blade Length]   varchar(50) --this is the Blade Length from dbo.tests  
 )  
/* Belt Recordset */  
DECLARE @Belts TABLE(  
  [BELT Event ID]   varchar(50), --this is the event_num from dbo.events  
  [BELT ID]    varchar(25), --this is the Belt ID form dbo.tests  
  [Belt On]    datetime,  --this is the belt on time from dbo.events  
  [Belt Off]    datetime  --this is the belt off time from dbo.events  
)  
DECLARE @FormingWire TABLE(  
  [FormingWire Event ID]   varchar(50), --this is the event_num from dbo.events  
  [FormingWire ID]    varchar(25), --this is the Forming Wire ID from dbo.tests  
  [FormingWire On]    datetime,  --this is the Forming Wire on time from dbo.events  
  [FormingWire Off]    datetime  --this is the Forming Wire off time from dbo.events  
)  
DECLARE @BackingWire TABLE(  
  [BackingWire Event ID]   varchar(50), --this is the event_num from dbo.events  
  [BackingWire ID]    varchar(25), --this is the Backing Wire ID from dbo.tests  
  [BackingWire On]    datetime,  --this is the Backing Wire on time from dbo.events  
  [BackingWire Off]    datetime  --this is the Backing Wire off time from dbo.events  
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
  
/* fill @MCharDesc */  
INSERT INTO @MCharDesc(CharDesc)  
 SELECT right (pl.pl_desc,4)  
  FROM dbo.prod_lines pl WITH (NOLOCK)  
   JOIN @Lines l ON l.PLID = pl.pl_id  
  
  
  
  
  
/* fill @Units  with the base data*/  
INSERT INTO @Units(PUID,Type,Line)  
 SELECT pu_id,  
  CASE  
   WHEN pu_desc like '% Production' THEN 1  
   WHEN pu_desc like '% Turnover Quality' THEN 2  
   WHEN pu_desc like '% Centerlines' THEN 3  
   WHEN pu_desc like '% Materials' THEN 4  
   ELSE 0  
  END,  
  left(pu_desc,4)  
  FROM dbo.prod_units pu WITH (NOLOCK)  
   JOIN @Lines l ON l.plid = pu.pl_id  
 WHERE pu.pu_desc like '% Centerlines' or pu.pu_desc like '% Turnover Quality' or pu.pu_desc like '% Production' or pu_desc like '% Materials'  
  
/* filling the base of @TOEvents */  
INSERT INTO @TOEvents(TID,EventID,EndTime,ProdPUID,Line)  
SELECT e.event_num,e.event_id,e.timestamp,u.puid,u.Line  
 FROM dbo.events e WITH (NOLOCK)  
  LEFT JOIN @Units u on u.puid = e.pu_id  
 WHERE (e.timestamp > = @Start and e.timestamp < @end) and u.Type = 1  
UPDATE toe  
 SET ClinPUID = u.puid  
 FROM @TOEvents toe, @Units u  
 WHERE u.type = 3  
/* fill in the starttime of @TOEvents */  
INSERT INTO @TOEStartTime(TOID,StartTime)  
SELECT TOID,EndTime FROM @TOEvents  
UPDATE t  
 SET t.StartTime = ts.StartTime  
 FROM @TOEvents t, @TOEStartTime ts  
 WHERE ts.TOID+1 = t.TOID  
DELETE @ToEvents WHERE StartTime is null  
  
/* get the Turnover Offical Weight for all the events in @ToEvents */  
UPDATE toe  
 SET toe.ToWeight = t.result  
 FROM @TOEvents toe  
  LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.result_on = toe.EndTime  
  LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.var_id = t.var_id and v.pu_id = toe.ProdPUID  
 WHERE v.var_desc = 'Turnover Weight Official'   
  
/* get the ProdId and Product for @ToEvents from dbo.products */  
UPDATE toe  
 SET ProdID = p.prod_id,  
  Product = p.prod_desc  
 FROM dbo.production_Starts ps WITH (NOLOCK)  
  LEFT JOIN dbo.products p WITH (NOLOCK) ON p.prod_id = ps.prod_id  
  JOIN @TOEvents toe ON toe.ProdPUID = ps.pu_id  
 WHERE ps.start_time <= toe.StartTime and (ps.end_time >= toe.EndTime or ps.end_time is null)  
/* get all the variables */  
 /* get the Production Unit Attribute Production Group Variables */  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SpecID,[Variable Type],Line)  
  SELECT v.var_id,v.var_desc,u.PUID,u.type,  
   CASE   
    WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
    ELSE v.eng_units  
   END,  
   v.spec_id,'Production',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE pu.pu_desc like '% Production' and pug.pug_desc = 'Attributes' and (var_desc like '% Reel %')  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
  
 /* get the Turnover Quality Turnover Testing Variables    
  2009-08-03 Vince King Modified WHERE statement to get variables from the Turnover Snap Process Variables PU Group */  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SPecID,[Variable Type],Line)  
  SELECT v.var_id,v.var_desc,u.PUID,u.type,  
   CASE   
    WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
    ELSE v.eng_units  
   END,  
   v.spec_id,'Quality',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE pu.pu_desc like '% Turnover Quality' and (pug.pug_desc = 'Turnover Testing' or pug.pug_desc = 'Turnover Snap Process Variables')   
    and (var_desc not like '% Day Avg' and var_desc not like '% Shift Avg')  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
  
 /* get the Turnover Qulaity QCS variables */  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SpecID,[Variable Type],Line)  
  SELECT v.var_id,v.var_desc,u.PUID,u.type,  
   CASE   
    WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
    ELSE v.eng_units  
   END,  
   v.spec_id,'Quality',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE pu.pu_desc like '% Turnover Quality' and pug.pug_desc = 'QCS' and (var_desc like '% Reel %')  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
 /* get the Turnover Quality Perfect Parent Roll Variables */  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SpecID,[Variable Type],Line)  
  SELECT v.var_id,v.var_desc,u.PUID,u.type,  
   CASE   
    WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
    ELSE v.eng_units  
   END,  
   v.spec_id,'Quality',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE pu.pu_desc like '% Turnover Quality' and pug.pug_desc = 'Perfect Parent Roll'  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
 /* get the Centerline Variables */  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SpecID,[Variable Type],Line)  
  SELECT v.var_id,  
    CASE  
     WHEN right(v.var_desc,10)= '15 Min Avg' THEN left(v.var_desc,len(v.var_desc)-10)  
     ELSE v.var_desc  
    END,  
    u.PUID,u.type,  
    CASE   
     WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
     ELSE v.eng_units  
    END,  
    v.spec_id,'Centerline',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE pu.pu_desc like '% Centerlines' and pug.pug_desc <> 'System'  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SpecID,[Variable Type],Line)  
  SELECT v.var_id,  
    CASE  
     WHEN right(v.var_desc,7)= 'TO Snap' THEN left(v.var_desc,len(v.var_desc)-7)  
     ELSE v.var_desc  
    END,  
    u.PUID,u.type,  
    CASE   
     WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
     ELSE v.eng_units  
    END,  
    v.spec_id,'Centerline',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE (pu.pu_desc like '% Turnover Quality' or pug.pug_desc like '% Turnover Snap %')  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
 /* get the Material Usage Variables */  
  INSERT INTO @VarsToGet (VarID,Variable,PUID,Type,EngUnits,SpecID,DataSource,[Variable Type],Line)  
  SELECT v.var_id,  
    CASE  
     WHEN right(v.var_desc,6)= 'Hr Avg' THEN left(v.var_desc,len(v.var_desc)-6)  
     ELSE v.var_desc  
    END,  
    u.PUID,u.type,  
    CASE   
     WHEN len(v.eng_units) = 0 or v.eng_units is null then 'Not Used'  
     ELSE v.eng_units  
    END,  
    v.spec_id,ds.ds_desc,'Materials',u.Line  
   FROM dbo.variables v WITH (NOLOCK)  
    JOIN dbo.pu_groups pug WITH (NOLOCK) ON pug.pug_id = v.pug_id  
    JOIN dbo.prod_units pu WITH (NOLOCK) On pu.pu_id = v.pu_id  
    JOIN dbo.data_type dt WITH (NOLOCK) ON dt.data_type_id = v.data_type_id  
    JOIN dbo.data_source ds WITH (NOLOCK) ON ds.ds_id = v.ds_id  
    JOIN @Units u ON u.puid = v.pu_id  
   WHERE pu.pu_desc like '% Materials' and pug.pug_desc <> 'System'  
    and (dt.data_type_desc = 'Integer' or dt.data_type_desc = 'Float')  
    and (v.var_desc like '% Hr Avg' or v.var_desc like '% Concentration' or v.var_desc like '% Density' or v.var_desc like '% Factor')  
/* get all the production event data */  
INSERT INTO @Data(TOID,VID,result)  
SELECT toe.TOID,vtg.VID,t.result  
 FROM dbo.tests t WITH (NOLOCK)  
  JOIN @VarsToGet vtg ON vtg.VARID = t.var_id and (vtg.Type = 2 or vtg.Type = 1)  
  JOIN @TOEvents toe ON toe.EndTime = t.result_on  
 WHERE t.result is not null  
/* get all the centerline data */  
INSERT INTO @BaseData(TOID,VID,result)  
SELECT toe.TOID,vtg.VID,  
 CASE   
  WHEN ISNUMERIC(t.result) = 1 THEN convert(real,t.result)  
 END  
 FROM dbo.tests t WITH (NOLOCK)  
  JOIN @VarsToGet vtg ON vtg.VarID = t.var_id  
  JOIN @TOEvents toe ON toe.ClinPUID = vtg.PUID  
 WHERE vtg.type = 3 and(t.result_on >=toe.StartTime and t.result_on < toe.EndTime) and t.result is not null  
  
INSERT INTO @Data(TOID,VID,result)  
 SELECT bd.TOID,bd.VID,avg(convert(real,bd.result))  
  FROM @BaseData bd  
  GROUP BY bd.TOID,bd.VID  
/* get the ProdID for @Data for all none Quality variables */  
UPDATE d  
 SET ProdID = ps.prod_ID  
 FROM @Data d  
  JOIN @VarsToGet vtg ON vtg.VID = d.VID  
  JOIN @TOEvents toe ON toe.TOID = d.TOID  
  JOIN dbo.production_starts ps WITH (NOLOCK) ON ps.pu_id = vtg.PUID  
 WHERE (ps.prod_id >1 and ps.start_time <=toe.StartTime and (ps.end_time >= toe.StartTime or ps.end_time is null)) and vtg.[Variable Type] <> 'Quality'  
  
/* get the ProdID for @Data  for all Quality Data*/  
UPDATE d  
 SET ProdID = ps.prod_ID  
 FROM @Data d  
  JOIN @VarsToGet vtg ON vtg.VID = d.VID  
  LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = vtg.PUID  
  JOIN @TOEvents toe ON toe.TOID = d.TOID  
  JOIN dbo.production_starts ps WITH (NOLOCK) ON ps.pu_id = pu.master_unit  
 WHERE (ps.prod_id >1 and ps.start_time <=toe.StartTime and (ps.end_time >= toe.StartTime or ps.end_time is null)) and vtg.[Variable Type] = 'Quality'  
  
/* get the material data */  
INSERT INTO @Materials(VID,Start,result)  
SELECT vtg.VID,t.result_on,t.result  
 FROM dbo.tests t WITH (NOLOCK)  
  JOIN @VarsToGet vtg ON vtg.VARID = t.var_id   
 WHERE (vtg.Type = 4) and (t.result_on >=@start and t.result_on < @End) and t.result is not null and (isnumeric(t.result) = 1)   
  
/* get the ProdID for @Materials */  
UPDATE d  
 SET ProdID = ps.prod_ID  
 FROM @Materials d  
  JOIN @VarsToGet vtg ON vtg.VID = d.VID  
  LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = vtg.PUID  
  LEFT JOIN dbo.production_starts ps WITH (NOLOCK) ON ps.pu_id = pu.master_unit  
 WHERE ps.prod_id >1 and ps.start_time <=d.Start and (ps.end_time >= d.Start or ps.end_time is null)  
/* get all the specifications for @Data */  
 UPDATE d  
  SET [Lower Reject Limit] = vs.L_Reject,  
   [Lower Warning Limit] = vs.L_Warning,  
   [Target] = vs.Target,  
   [Upper Warning Limit] =vs.U_Warning,  
   [Upper Reject Limit] = vs.U_Reject  
  FROM @Data d  
   JOIN @VarsToGet vtg ON vtg.VID = d.VID  
   JOIN @TOEvents toe ON toe.TOID = d.TOID  
   LEFT JOIN dbo.var_specs vs WITH (NOLOCK) ON vs.var_id = vtg.[VarID] and vs.prod_id = d.ProdID  
  WHERE vs.effective_date <= toe.StartTime and (vs.expiration_date >= toe.StartTime or vs.expiration_date is null)  
  
/* get all the specifications for @Materials */  
 UPDATE d  
  SET [Lower Reject Limit] = vs.L_Reject,  
   [Lower Warning Limit] = vs.L_Warning,  
   [Target] = vs.Target,  
   [Upper Warning Limit] =vs.U_Warning,  
   [Upper Reject Limit] = vs.U_Reject  
  FROM @Materials d  
   JOIN @VarsToGet vtg ON vtg.VID = d.VID  
   LEFT JOIN dbo.var_specs vs WITH (NOLOCK) ON vs.var_id = vtg.[VarID] and vs.prod_id = d.ProdID  
  WHERE vs.effective_date <= d.Start and (vs.expiration_date >= d.Start or vs.expiration_date is null)  
/* get the specs for all the other type variables of Materials */  
INSERT INTO @Materials(VID,Start,[End],Result,target)  
SELECT vtg.VID,aspecs.effective_date,aspecs.expiration_date,aspecs.target,aspecs.target  
 FROM @varstoget vtg  
   LEFT JOIN dbo.specifications specs WITH (NOLOCK) ON specs.spec_id = vtg.SpecID --and (type = 4 and DataSource = 'Other')  
   LEFT JOIN dbo.product_properties pp WITH (NOLOCK) ON pp.prop_id = specs.prop_id  
   LEFT JOIN dbo.characteristics c WITH (NOLOCK) ON c.prop_id = pp.prop_id  
   JOIN dbo.active_specs aspecs WITH (NOLOCK) ON  aspecs.spec_id= vtg.SpecID and aspecs.char_id = c.char_id  
   JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = vtg.PUID   
   JOIN dbo.prod_lines pl WITH (NOLOCK) ON pl.pl_id = pu.pl_id  
   JOIN @MCharDesc m ON m.CharDesc = c.char_desc  
  WHERE  
   (type = 4 and DataSource = 'Other')  
   and   
   (aspecs.effective_date <= @Start and (aspecs.expiration_date >= @Start or aspecs.expiration_date is null))  
  
  
/* get all the cleaning blade change data */  
IF (SELECT  app_version FROM [dbo].appversions WITH (NOLOCK) WHERE app_name = 'Database') > 400000.000  
 BEGIN  
 INSERT INTO @CleaningBlades ([Blade Change ID],[Line],[Timestamp],[puid])  
 SELECT   
  e.event_num,left(pu.pu_desc,4),e.timestamp,e.pu_id  
             FROM dbo.events e WITH (NOLOCK)  
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
           WHERE (@Start<=e.timestamp  and e.timestamp < @End)   
                                    and pu.pu_desc like '% Cleaning Blade'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
            ORDER BY pu.pu_desc,e.event_id,eh.entry_on   
 UPDATE e  
 SET [TID]=   
  CASE  
   WHEN t2.result is not null then t2.result  
   ELSE 'No TID Assgined'  
   END,   
  [Blade Life]=   
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'Blade Still Running'  
   END,  
  [Blade Change Duration]=  
  CASE  
   WHEN t1.result is not null then t1.result  
   ELSE 'No Change Duration'  
   END,   
  [Blade Change Cause]=   
  CASE  
   WHEN t3.result is not null then t3.result  
   WHEN t3.result = '<Select Cause>' THEN 'No Cause Assigned'  
   ELSE 'No Cause Assigned'  
   END,   
  [Blade Change Reason]=   
  CASE  
   WHEN t4.result is not null then t4.result  
   WHEN t4.result = '<Select Reason>' THEN 'No Reason Assigned'  
   ELSE 'No Reason Assigned'  
   END,   
  [Blade Angle]=  
  CASE  
   WHEN t5.result is not null then t5.result  
   ELSE 'No Blade Angle Assigned'  
   END,   
  [Blade Free Height]=  
  CASE  
   WHEN t6.result is not null then t6.result  
   ELSE 'No Blade Free Height Assigned'  
   END,   
  [Blade Height]=  
  CASE  
   WHEN t7.result is not null then t7.result  
   ELSE 'No Blade Height Assigned'  
   END,   
  [Blade Length]=  
  CASE  
   WHEN t8.result is not null then t8.result  
   ELSE 'No Blade Length Assigned'  
   END  
  FROM @CleaningBlades e  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.puid and v.var_desc = 'Cleaning Blade Life'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.puid and v1.var_desc = 'Cleaning Blade Change Duration'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v2 WITH (NOLOCK) ON v2.pu_id = e.puid and v2.var_desc = 'Cleaning Blade Change Turnover'  
                        LEFT JOIN dbo.tests t2 WITH (NOLOCK) ON t2.var_id = v2.var_id and t2.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v3 WITH (NOLOCK) ON v3.pu_id = e.puid and v3.var_desc = 'Cleaning Blade Change Cause'  
                        LEFT JOIN dbo.tests t3 WITH (NOLOCK) ON t3.var_id = v3.var_id and t3.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v4 WITH (NOLOCK) ON v4.pu_id = e.puid and v4.var_desc = 'Cleaning Blade Change Reason'  
                        LEFT JOIN dbo.tests t4 WITH (NOLOCK) ON t4.var_id = v4.var_id and t4.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v5 WITH (NOLOCK) ON v5.pu_id = e.puid and v5.var_desc = 'Cleaning Blade Angle'  
                        LEFT JOIN dbo.tests t5 WITH (NOLOCK) ON t5.var_id = v5.var_id and t5.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v6 WITH (NOLOCK) ON v6.pu_id = e.puid and v6.var_desc = 'Cleaning Blade Free Height'  
                        LEFT JOIN dbo.tests t6 WITH (NOLOCK) ON t6.var_id = v6.var_id and t6.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v7 WITH (NOLOCK) ON v7.pu_id = e.puid and v7.var_desc = 'Cleaning Blade Height'  
                        LEFT JOIN dbo.tests t7 WITH (NOLOCK) ON t7.var_id = v7.var_id and t7.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v8 WITH (NOLOCK) ON v8.pu_id = e.puid and v8.var_desc = 'Cleaning Blade Length'  
                        LEFT JOIN dbo.tests t8 WITH (NOLOCK) ON t8.var_id = v8.var_id and t8.result_on = e.timestamp   
           WHERE (@Start<=e.timestamp  and e.timestamp < @End)   
  
  
 /* get all the Creping blade change data */  
 INSERT INTO @CrepingBlades ([Blade Change ID],[Line],[Timestamp],[puid])  
 SELECT   
   e.event_num,left(pu.pu_desc,4),e.timestamp,e.pu_id  
               FROM dbo.events e WITH (NOLOCK)  
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
            WHERE (@Start<=e.timestamp  and e.timestamp < @End)   
                                    and pu.pu_desc like '% Creping Blade'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
             ORDER BY pu.pu_desc,e.event_id,eh.entry_on   
 UPDATE e  
 SET [TID]=   
  CASE  
   WHEN t2.result is not null then t2.result  
   ELSE 'No TID Assgined'  
   END,   
  [Blade Life]=   
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'Blade Still Running'  
   END,  
  [Blade Change Duration]=  
  CASE  
   WHEN t1.result is not null then t1.result  
   ELSE 'No Change Duration'  
   END,   
  [Blade Change Cause]=   
  CASE  
   WHEN t3.result is not null then t3.result  
   WHEN t3.result = '<Select Cause>' THEN 'No Cause Assigned'  
   ELSE 'No Cause Assigned'  
   END,   
  [Blade Change Reason]=   
  CASE  
   WHEN t4.result is not null then t4.result  
   WHEN t4.result = '<Select Reason>' THEN 'No Reason Assigned'  
   ELSE 'No Reason Assigned'  
   END,   
  [Blade Angle]=  
  CASE  
   WHEN t5.result is not null then t5.result  
   ELSE 'No Blade Angle Assigned'  
   END,   
  [Blade Free Height]=  
  CASE  
   WHEN t6.result is not null then t6.result  
   ELSE 'No Blade Free Height Assigned'  
   END,   
  [Blade Height]=  
  CASE  
   WHEN t7.result is not null then t7.result  
   ELSE 'No Blade Height Assigned'  
   END,   
  [Blade Length]=  
  CASE  
   WHEN t8.result is not null then t8.result  
   ELSE 'No Blade Length Assigned'  
   END  
  FROM @CrepingBlades e  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.puid and v.var_desc = 'Creping Blade Life'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.puid and v1.var_desc = 'Creping Blade Change Duration'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v2 WITH (NOLOCK) ON v2.pu_id = e.puid and v2.var_desc = 'Creping Blade Change Turnover'  
                        LEFT JOIN dbo.tests t2 WITH (NOLOCK) ON t2.var_id = v2.var_id and t2.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v3 WITH (NOLOCK) ON v3.pu_id = e.puid and v3.var_desc = 'Creping Blade Change Cause'  
                        LEFT JOIN dbo.tests t3 WITH (NOLOCK) ON t3.var_id = v3.var_id and t3.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v4 WITH (NOLOCK) ON v4.pu_id = e.puid and v4.var_desc = 'Creping Blade Change Reason'  
                        LEFT JOIN dbo.tests t4 WITH (NOLOCK) ON t4.var_id = v4.var_id and t4.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v5 WITH (NOLOCK) ON v5.pu_id = e.puid and v5.var_desc = 'Creping Blade Angle'  
                        LEFT JOIN dbo.tests t5 WITH (NOLOCK) ON t5.var_id = v5.var_id and t5.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v6 WITH (NOLOCK) ON v6.pu_id = e.puid and v6.var_desc = 'Creping Blade Free Height'  
                        LEFT JOIN dbo.tests t6 WITH (NOLOCK) ON t6.var_id = v6.var_id and t6.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v7 WITH (NOLOCK) ON v7.pu_id = e.puid and v7.var_desc = 'Creping Blade Height'  
                        LEFT JOIN dbo.tests t7 WITH (NOLOCK) ON t7.var_id = v7.var_id and t7.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v8 WITH (NOLOCK) ON v8.pu_id = e.puid and v8.var_desc = 'Creping Blade Length'  
                        LEFT JOIN dbo.tests t8 WITH (NOLOCK) ON t8.var_id = v8.var_id and t8.result_on = e.timestamp   
           WHERE (@Start<=e.timestamp  and e.timestamp < @End)   
 END  
IF (SELECT  app_version FROM [dbo].appversions WITH (NOLOCK) WHERE app_name = 'Database') < 400000.000  
 BEGIN  
  
/* get all the cleaning blade change data */  
INSERT INTO @CleaningBlades ([Blade Change ID],[Line],[TID],[Blade Life],[Blade Change Duration],[Blade Change Cause],  
   [Blade Change Reason],[Blade Angle],[Blade Free Height],[Blade Height],[Blade Length])  
SELECT   
 e.event_num, left(pu.pu_desc,4),  
  CASE  
   WHEN t2.result is not null then t2.result  
   ELSE 'No TID Assgined'  
   END,   
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'Blade Still Running'  
   END,  
  CASE  
   WHEN t1.result is not null then t1.result  
   ELSE 'No Change Duration'  
   END,   
  CASE  
   WHEN t3.result is not null then t3.result  
   WHEN t3.result = '<Select Cause>' THEN 'No Cause Assigned'  
   ELSE 'No Cause Assigned'  
   END,   
  CASE  
   WHEN t4.result is not null then t4.result  
   WHEN t4.result = '<Select Reason>' THEN 'No Reason Assigned'  
   ELSE 'No Reason Assigned'  
   END,   
  CASE  
   WHEN t5.result is not null then t5.result  
   ELSE 'No Blade Angle Assigned'  
   END,   
  CASE  
   WHEN t6.result is not null then t6.result  
   ELSE 'No Blade Free Height Assigned'  
   END,   
  CASE  
   WHEN t7.result is not null then t7.result  
   ELSE 'No Blade Height Assigned'  
   END,   
  CASE  
   WHEN t8.result is not null then t8.result  
   ELSE 'No Blade Length Assigned'  
   END  
             FROM dbo.events e WITH (NOLOCK)  
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.pu_id and v.var_desc = 'Cleaning Blade Life'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.pu_id and v1.var_desc = 'Cleaning Blade Change Duration'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v2 WITH (NOLOCK) ON v2.pu_id = e.pu_id and v2.var_desc = 'Cleaning Blade Change Turnover'  
                        LEFT JOIN dbo.tests t2 WITH (NOLOCK) ON t2.var_id = v2.var_id and t2.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v3 WITH (NOLOCK) ON v3.pu_id = e.pu_id and v3.var_desc = 'Cleaning Blade Change Cause'  
                        LEFT JOIN dbo.tests t3 WITH (NOLOCK) ON t3.var_id = v3.var_id and t3.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v4 WITH (NOLOCK) ON v4.pu_id = e.pu_id and v4.var_desc = 'Cleaning Blade Change Reason'  
                        LEFT JOIN dbo.tests t4 WITH (NOLOCK) ON t4.var_id = v4.var_id and t4.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v5 WITH (NOLOCK) ON v5.pu_id = e.pu_id and v5.var_desc = 'Cleaning Blade Angle'  
                        LEFT JOIN dbo.tests t5 WITH (NOLOCK) ON t5.var_id = v5.var_id and t5.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v6 WITH (NOLOCK) ON v6.pu_id = e.pu_id and v6.var_desc = 'Cleaning Blade Free Height'  
                        LEFT JOIN dbo.tests t6 WITH (NOLOCK) ON t6.var_id = v6.var_id and t6.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v7 WITH (NOLOCK) ON v7.pu_id = e.pu_id and v7.var_desc = 'Cleaning Blade Height'  
                        LEFT JOIN dbo.tests t7 WITH (NOLOCK) ON t7.var_id = v7.var_id and t7.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v8 WITH (NOLOCK) ON v8.pu_id = e.pu_id and v8.var_desc = 'Cleaning Blade Length'  
                        LEFT JOIN dbo.tests t8 WITH (NOLOCK) ON t8.var_id = v8.var_id and t8.result_on = e.timestamp   
           WHERE (@Start<=e.timestamp  and e.timestamp < @End)   
                                    and pu.pu_desc like '% Cleaning Blade'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
            ORDER BY pu.pu_desc,e.event_id,eh.entry_on   
  
/* get all the Creping blade change data */  
INSERT INTO @CrepingBlades ([Blade Change ID],[Line],[TID],[Blade Life],[Blade Change Duration],[Blade Change Cause],  
   [Blade Change Reason],[Blade Angle],[Blade Free Height],[Blade Height],[Blade Length])  
SELECT   
 e.event_num,left(pu.pu_desc,4),  
  CASE  
   WHEN t2.result is not null then t2.result  
   ELSE 'No TID Assgined'  
   END,   
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'Blade Still Running'  
   END,  
  CASE  
   WHEN t1.result is not null then t1.result  
   ELSE 'No Change Duration'  
   END,   
  CASE  
   WHEN t3.result is not null then t3.result  
   WHEN t3.result = '<Select Cause>' THEN 'No Cause Assigned'  
   ELSE 'No Cause Assigned'  
   END,   
  CASE  
   WHEN t4.result is not null then t4.result  
   WHEN t4.result = '<Select Reason>' THEN 'No Reason Assigned'  
   ELSE 'No Reason Assigned'  
   END,   
  CASE  
   WHEN t5.result is not null then t5.result  
   ELSE 'No Blade Angle Assigned'  
   END,   
  CASE  
   WHEN t6.result is not null then t6.result  
   ELSE 'No Blade Free Height Assigned'  
   END,   
  CASE  
   WHEN t7.result is not null then t7.result  
   ELSE 'No Blade Height Assigned'  
   END,   
  CASE  
   WHEN t8.result is not null then t8.result  
   ELSE 'No Blade Length Assigned'  
   END  
             FROM dbo.events e WITH (NOLOCK)  
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.pu_id and v.var_desc = 'Creping Blade Life'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.pu_id and v1.var_desc = 'Creping Blade Change Duration'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v2 WITH (NOLOCK) ON v2.pu_id = e.pu_id and v2.var_desc = 'Creping Blade Change Turnover'  
                        LEFT JOIN dbo.tests t2 WITH (NOLOCK) ON t2.var_id = v2.var_id and t2.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v3 WITH (NOLOCK) ON v3.pu_id = e.pu_id and v3.var_desc = 'Creping Blade Change Cause'  
                        LEFT JOIN dbo.tests t3 WITH (NOLOCK) ON t3.var_id = v3.var_id and t3.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v4 WITH (NOLOCK) ON v4.pu_id = e.pu_id and v4.var_desc = 'Creping Blade Change Reason'  
                        LEFT JOIN dbo.tests t4 WITH (NOLOCK) ON t4.var_id = v4.var_id and t4.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v5 WITH (NOLOCK) ON v5.pu_id = e.pu_id and v5.var_desc = 'Creping Blade Angle'  
                        LEFT JOIN dbo.tests t5 WITH (NOLOCK) ON t5.var_id = v5.var_id and t5.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v6 WITH (NOLOCK) ON v6.pu_id = e.pu_id and v6.var_desc = 'Creping Blade Free Height'  
                        LEFT JOIN dbo.tests t6 WITH (NOLOCK) ON t6.var_id = v6.var_id and t6.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v7 WITH (NOLOCK) ON v7.pu_id = e.pu_id and v7.var_desc = 'Creping Blade Height'  
                        LEFT JOIN dbo.tests t7 WITH (NOLOCK) ON t7.var_id = v7.var_id and t7.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v8 WITH (NOLOCK) ON v8.pu_id = e.pu_id and v8.var_desc = 'Creping Blade Length'  
                        LEFT JOIN dbo.tests t8 WITH (NOLOCK) ON t8.var_id = v8.var_id and t8.result_on = e.timestamp   
           WHERE (@Start<=e.timestamp  and e.timestamp < @End)   
                                    and pu.pu_desc like '% Creping Blade'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
            ORDER BY pu.pu_desc,e.event_id,eh.entry_on   
END  
/*get the belt data */  
INSERT INTO @Belts([BELT Event ID],[BELT ID],[Belt On],[Belt Off])  
SELECT   
 e.event_num,  
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'No Belt ID'  
   END,  
  CASE  
   WHEN ps1.prodstatus_desc ='Running' THEN e.entry_on  
   WHEN ps1.prodstatus_desc = 'Removed' THEN eh.entry_on    
   END,  
  CASE  
   WHEN  isdate(t1.result) = 1 and t1.result is not null then t1.result  
   ELSE @Now  
   END  
             FROM dbo.events e WITH (NOLOCK)  
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.pu_id and v.var_desc = 'Belt ID'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.pu_id and v1.var_desc = 'Belt Off Timestamp'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
           WHERE (dateadd(month,-3,@Start)<=e.entry_on  and e.timestamp < @End)   
                                    and (ps2.prodstatus_desc<> 'Inventory' and ps2.prodstatus_desc <> 'Complete' and ps2.prodstatus_desc <> 'Next On')  
                                    and pu.pu_desc like '% Belt'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
  
/*get the forming wire data */  
INSERT INTO @FormingWire([FormingWire Event ID],[FormingWire ID],[FormingWire On],[FormingWire Off])  
SELECT   
 e.event_num,  
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'No Wire ID'  
   END,  
  CASE  
   WHEN ps1.prodstatus_desc ='Running' THEN e.entry_on  
   WHEN ps1.prodstatus_desc = 'Removed' THEN eh.entry_on    
   END,  
  CASE  
   WHEN isdate(t1.result) = 1 and t1.result is not null then t1.result  
   ELSE @Now  
   END  
             FROM dbo.events e WITH (NOLOCK)  
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.pu_id and v.var_desc = 'Forming Wire ID'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.pu_id and v1.var_desc = 'Forming Wire Off Timestamp'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
           WHERE (dateadd(month,-3,@Start)<=e.entry_on  and e.timestamp < @End)   
                                    and (ps2.prodstatus_desc<> 'Inventory' and ps2.prodstatus_desc <> 'Complete' and ps2.prodstatus_desc <> 'Next On')  
                                    and pu.pu_desc like '% Forming Wire'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
/* Update @ToEvents with [FormingWire ID] and [Belt ID] */  
UPDATE toe  
 SET [FormingWire ID] = fw.[FormingWire ID]  
 FROM @TOEvents toe,@FormingWire fw  
 WHERE fw.[FormingWire On]<=toe.StartTime and fw.[FormingWire Off] >= toe.EndTime  
  
UPDATE toe  
 SET [Belt ID] = b.[Belt ID]  
 FROM @TOEvents toe,@Belts b  
 WHERE b.[Belt On]<=toe.StartTime and b.[Belt Off] >= toe.EndTime  
  
/*get the backing wire data */  
INSERT INTO @BackingWire([BackingWire Event ID],[BackingWire ID],[BackingWire On],[BackingWire Off])  
SELECT   
 e.event_num,  
  CASE  
   WHEN t.result is not null THEN t.result  
   ELSE 'No Wire ID'  
   END,  
  CASE  
   WHEN ps1.prodstatus_desc ='Running' THEN e.entry_on  
   WHEN ps1.prodstatus_desc = 'Removed' THEN eh.entry_on    
   END,  
  CASE  
   WHEN  isdate(t1.result) = 1 and t1.result is not null then t1.result  
   ELSE @Now  
   END  
             FROM dbo.events e WITH (NOLOCK)   
                        LEFT JOIN dbo.event_history eh WITH (NOLOCK) ON eh.event_id = e.event_id   
                        LEFT JOIN dbo.production_status ps1 WITH (NOLOCK) ON ps1.prodstatus_id = e.event_status   
                        LEFT JOIN dbo.production_status ps2 WITH (NOLOCK) ON ps2.prodstatus_id = eh.event_status   
                        LEFT JOIN dbo.prod_units pu WITH (NOLOCK) ON pu.pu_id = e.pu_id  
      JOIN @Lines l ON l.plid = pu.pl_id  
                        LEFT JOIN dbo.variables v WITH (NOLOCK) ON v.pu_id = e.pu_id and v.var_desc = 'Backing Wire ID'  
                        LEFT JOIN dbo.tests t WITH (NOLOCK) ON t.var_id = v.var_id and t.result_on = e.timestamp   
                        LEFT JOIN dbo.variables v1 WITH (NOLOCK) ON v1.pu_id = e.pu_id and v1.var_desc = 'Backing Wire Off Timestamp'  
                        LEFT JOIN dbo.tests t1 WITH (NOLOCK) ON t1.var_id = v1.var_id and t1.result_on = e.timestamp   
           WHERE (dateadd(month,-3,@Start)<=e.entry_on  and e.timestamp < @End)   
                                    and (ps2.prodstatus_desc<> 'Inventory' and ps2.prodstatus_desc <> 'Complete' and ps2.prodstatus_desc <> 'Next On')  
                                    and pu.pu_desc like '% Backing Wire'   
                                    and (ps2.prodstatus_desc = 'Running'  or ps1.prodstatus_desc = 'Running')  
/* Update @ToEvents with [FormingWire ID], [BackingWire ID], and [Belt ID] */  
UPDATE toe  
 SET [FormingWire ID] = fw.[FormingWire ID]  
 FROM @TOEvents toe,@FormingWire fw  
 WHERE fw.[FormingWire On]<=toe.StartTime and fw.[FormingWire Off] >= toe.EndTime  
  
UPDATE toe  
 SET [BackingWire ID] =bw.[BackingWire ID]  
 FROM @TOEvents toe,@BackingWire bw  
 WHERE bw.[BackingWire On]<=toe.StartTime and bw.[BackingWire Off] >= toe.EndTime  
UPDATE toe  
 SET [Belt ID] = b.[Belt ID]  
 FROM @TOEvents toe,@Belts b  
 WHERE b.[Belt On]<=toe.StartTime and b.[Belt Off] >= toe.EndTime  
   
ReturnRecordSets:  
  
/*return the turnover variable data */  
 SELECT toe.TID,toe.Line,toe.StartTime,toe.EndTime,TOE.Product,toe.[Belt ID],toe.[FormingWire ID],toe.[BackingWire ID],  
   vtg.[Variable Type],vtg.Variable,vtg.EngUnits,d.Result,d.[Lower Reject Limit],  
   d.[Lower Warning Limit],d. Target,d.[Upper Warning Limit],d.[Upper Reject Limit]  
  FROM @Data d  
   JOIN @VarsToGet vtg ON vtg.VID = d.VID  
   JOIN @TOEvents toe ON toe.TOID = d.TOID   
/*return the materials recordset */  
 SELECT vtg.Line,d.Start,d.[End],[Product] =  
   CASE  
    WHEN d.ProdID is not null THEN p.prod_desc  
    ELSE 'Materials Constant'  
   END,  
   vtg.[Variable Type],vtg.Variable,vtg.EngUnits,d.Result,d.[Lower Reject Limit],  
   d.[Lower Warning Limit],d. Target,d.[Upper Warning Limit],d.[Upper Reject Limit]  
  FROM @Materials d  
   JOIN @VarsToGet vtg ON vtg.VID = d.VID  
   LEFT JOIN dbo.products p WITH (NOLOCK) ON p.prod_id = d.ProdID  
/* return the creping blade data */  
 SELECT * FROM @CrepingBlades  
/* return the cleaning blade data */  
 SELECT * FROM @CleaningBlades  
  
