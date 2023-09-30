 /*  
Stored Procedure: spLocal_GetLogWeight  
Author:   Fran Osorno  
Date Created:  Jan 26, 2006  
  
Description:  
=========  
  
  @OutputValue varchar(25) OUTPUT,  --This is the Output value  
  @EventID  int,     --This is the EventID of the evnet  
  @EventTime datetime,    --This is the event time  
  @Units  int,     --The is the number of total units made for the production event  
  @PUID  int     --This is the pu_id of the event  
      
  
Change Date Who  What  
======== ==== =====  
Jan 26, 2006 FGO  Created procedure  
*/  
  
CREATE  PROCEDURE dbo.spLocal_GetLogWeight  
  
  @OutputValue varchar(25) OUTPUT,    
  @EventID  int,  
  @EventTime datetime,  
  @Units  int,  
  @PUID  int  
as  
  
/******************************************/  
/*     Global execution switches            */   
/******************************************/  
 SET NOCOUNT ON  
 SET ANSI_WARNINGS OFF  
/******************************************/  
/*   TESTING            */  
/*  Values into the Code             */  
/*****************************************/  
-- DECLARE  
--  @OutputValue varchar(25),  
--  @EventID  int,  
--  @EventTime datetime,  
--  @Units  int,  
--  @PUID  int  
  
/***************************************/  
/*   TESTING     */  
/*  set the values into the Code  */  
/********************************** ****/  
  
/* set the values into the Code */  
-- SELECT @EventID = 6326080,@EventTime = '1/18/06 18:33:51', @PUID = 1103,@Units=1013  
  
/*****************************************/  
/*   declare variables used within the code  */  
/****************************************/  
 DECLARE  
  @EventProdID  int,   --This is the prod_id running at the @EventTime  
  @EventEventNum varchar(50), --This is the evnet_num for the event a the @EventTime  
  @EventProdCode varchar(8), --This is the prod_code runing at the @EventTime  
  @EventCharID  int,   --This is the char_id runing at the @EventTime  
  @SheetCount  int,   --This is the sheet count of the running production at the @EventTime  
  @SheetLength  real,   --This is the sheet length of the running production at the @EventTime  
  @SheetLengthEU varchar(10), --This is the sheet length eng/Units of the running production at the @EventTime  
  @SheetWidth  real,   --This is the sheet width of the running production at the @EventTime  
  @SheetWidthEU varchar(10), --This is the sheet width eng/Units of the running production at the @EventTime  
  @RollsEventTime datetime,  --This is the time of the Rolls Event  
  @RollsPUID  int,   --This is the pu_id of the rolls unit  
  @RollWidth  real,   --This is the roll width offical for the rolls event  
  @RollWidthEU  varchar(10), --This is the roll width offical eng/units for the roll event  
  @BW    real,   --This is the basis weight manual for the rolls event  
  @BWEU   varchar(10), --This is the basis weight manual eng/units for the rolls event   
  @mmToin   float,   --This is the converssion for mm to in  
  @BWConv   float   --This is the convsersion of lbs/3000 sg ft to kg/sq mm  
  
/*******************************************************/  
/*   Set conversions                                                                     */  
/*  @ BWConv = .00033*.00694*.00155*.453597          */  
/*                   that equals 0.00000000161018317            */  
/*******************************************************/  
  
 SELECT @mmToin = 25.4, @BWConv = 0.00000000161018317  
  
  
/*******************************************************/  
/*   Set @EventProdID                                                                     */  
/*******************************************************/  
   
 SELECT @EventProdID = p.prod_id, @EventProdCode = p.prod_code   
  FROM dbo.production_starts  ps  
   LEFT JOIN dbo.products  p on (p.prod_id = ps.prod_id)  
  WHERE pu_id = @PUID and (start_time<= @EventTime and (end_time >= @EventTime or end_time is null))  
  
/*******************************************************/  
/*   Set @EventCharID            */  
/*******************************************************/  
  
 SELECT @EventCharID=char_id  
  FROM dbo.characteristics  c  
   JOIN dbo.product_properties  pp on (pp.prop_id = c.prop_id and c.char_desc = @EventProdCode and pp.prop_desc like '% Prod Factors')  
  
/*******************************************************/  
/*   Set @SheetCount                                                                */  
/*******************************************************/  
  
 SELECT @SheetCount = convert(int,convert(real,target))  
  FROM dbo.active_specs  aspec  
   JOIN dbo.specifications  specs on (specs.spec_id = aspec.spec_id and aspec.char_id = @EventCharID and specs.spec_desc ='Sheet Count')  
  
/*******************************************************/  
/*   Set @SheetLength @SheetLengthEU                                        */  
/*******************************************************/  
  
 SELECT @SheetLength = convert(real,target),@SheetLengthEU = eng_units  
  FROM dbo.active_specs aspec  
   JOIN dbo.specifications specs on (specs.spec_id = aspec.spec_id and aspec.char_id = @EventCharID and specs.spec_desc ='Sheet Length')  
  
/*******************************************************/  
/*   Set @SheetWidth @SheetWidthEU                                            */  
/*******************************************************/  
  
 SELECT @SheetWidth = convert(real,target),@SheetWidthEU = eng_units  
  FROM dbo.active_specs aspec  
   JOIN dbo.specifications specs on (specs.spec_id = aspec.spec_id and aspec.char_id = @EventCharID and specs.spec_desc ='Sheet Width')  
  
/*******************************************************/  
/*   Set @EventEventNum              */  
/*   @RollsEventTime and @RollsPUID           */  
/*******************************************************/  
  
 SELECT @EventEventNum = event_num FROM dbo.events WHERE event_id =@EventID  
 SELECT @RollsEventTime = timestamp, @RollsPUID =pu_id FROM dbo.events WHERE event_num = @EventEventNum and pu_ID <> @PUID  
  
/*******************************************************/  
/*   Set @BW @BWEU               */  
/*******************************************************/  
 SELECT top  1 @BW= t.result,@BWEU = eng_units  
  FROM dbo.TESTS t  
   JOIN dbo.variables v on (v.var_id = t.var_id  and v.pu_id = @RollsPUID and v.var_desc = 'Basis Weight Manual' and t.result_on <=@RollsEventTime)  
  ORDER BY result_on desc  
  
/*******************************************************/  
/*   Set @SheetWidth @SheetWidthEU            */  
/*******************************************************/  
 SELECT top 1 @RollWidth= t.result,@RollWidthEU = eng_units  
  FROM dbo.TESTS t  
   JOIN dbo.variables v on (v.var_id = t.var_id  and v.pu_id = @RollsPUID and v.var_desc = 'Roll Width Official' and t.result_on <=@RollsEventTime)  
  ORDER BY result_on desc  
  
/*******************************************************/  
/*   Do the covnersions to metric                */  
/*******************************************************/  
 IF @SheetLengthEU <> 'mm'  
  BEGIN  
   SELECT @SheetLength = @SheetLength * @mmToin  
  END  
  
 IF @SheetWidthEU <> 'mm'  
  BEGIN  
   SELECT @SheetWidth = @SheetWidth * @mmToin  
  END  
  
 IF @RollWidthEU <> 'mm'  
  BEGIN  
   SELECT @RollWidth = @RollWidth * @mmToin  
  END  
 IF @BWEU = 'lbs/ream'  
  BEGIN  
   SELECT @BW = @BW * @BWConv  
  END  
/*******************************************************/  
/*   Calc @OutputValue                  */  
/*******************************************************/  
  
 SELECT @OutputValue=convert(varchar(25),(@bw * floor(@rollWidth/@sheetwidth) *@SheetCount *@Units*  @SheetWidth * @SheetLength)/1000)  
