   /*  
Stored Procedure: spLocal_GlblChangeOverSheet  
Author:    Fran Osorno  
Date Created:  04/22/2004  
Version:    1.0  
  
Description:  
=========  
This procedure will return data to build a change over sheet in converting     
  
functions Used   
 GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces  
  
  
Change Date  Who  What  
=========== ====  =====  
04/22/0225   FGO   Created  
02/23/07   FGO   updated to best practices  
06/25/08   fgo   changed code to global name and for coding practices  
*/  
  
CREATE   PROCEDURE dbo.spLocal_GlblChangeOverSheet  
  
/*Declare Variables Passed to the code */  
  @SheetDesc  VARCHAR(50),  --this is the sheet to use  
  @CharDesc  VARCHAR(50)  --this is the caracteristic selected  
AS  
/*Declare Variables used in the code */  
 DECLARE  
  @LinkStrPerson  VARCHAR(100),  --this is the link string for Change Over Person  
  @LinkStrStep  VARCHAR(100),  --this is the link string for Changer Over Person  
  @LinkStrStepName VARCHAR(300),  --this is the link string for Change Over Step Name  
  @LinkStrHint  VARCHAR(4000)  --this is the link string for Change Over Hint  
/*Declare the temp Table Variable */  
 DECLARE  
  @Data TABLE(  
   Variable  VARCHAR(50),  --this is the var_desc  
   VAR_ID  INT,   --this is the var_id  
   Spec_ID  INT,   --this is the spec_id of the variable  
   Prop_ID  INT,   --this is the prop_id of the spec  
   Char_ID  INT,   --this is the char_id of @CharDesc  
   Var_order INT,   --this is the order of the report  
   COPerson VARCHAR(25),  --this is the changeover person  
   COStepName VARCHAR(300),  --this is the changeover step description  
   Setting  VARCHAR(25),  --this is the changeover setting  
   COHint  VARCHAR(4000),  --this is the changeover hint  
   COHint1  VARCHAR(255),  --this is the hint as part of extended_info  
   COHint2  VARCHAR(255),  --this is the hint as part of user_defined1  
   COHint3  VARCHAR(255),  --this is the hint as part of user_defined2  
   COHint4  VARCHAR(255)  --this is the hint as part of user_defined3  
  )     
     
  
/* set the variables passed to the code for testing */  
/* SELECT @SheetDesc = 'FTL4 East Wrapper Changeover',  
  @CharDesc = 'CH UL 12GR'  
*/  
  
/*set the code variables as needed */  
 SELECT @LinkStrPerson = 'COPerson=',  
  @LinkStrStepName = 'COStepName=',  
  @LinkStrHint = 'COHint='  
   
/* Place the data in @Data */  
 INSERT INTO @Data(Variable,Var_ID,Spec_ID,prop_ID,  
   Var_order,COPerson,COStepName,COHint1,COHint2,COHint3,COHint4)  
  SELECT  [Variable]=  
    CASE   
     WHEN title IS Null THEN var_desc  
     ELSE title  
    END,  
   sv.var_id,  
   v.spec_ID,  
   specs.prop_id,  
   sv.var_order,  
   GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces(v.extended_info,@LinkStrPerson),  
   GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces(v.extended_info,@LinkStrStepName),  
   GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces(v.extended_info,@LinkStrHint),  
   GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces(v.user_defined1,@LinkStrHint) ,  
   GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces(v.user_defined2,@LinkStrHint) ,  
   GBDB.dbo.fnLocal_GlblCOParseInfoWithSpaces(v.user_defined3,@LinkStrHint)  
  FROM dbo.sheets  s with(nolock)  
   LEFT JOIN dbo.sheet_variables  sv with(nolock) ON (sv.sheet_id = s.sheet_id)  
   LEFT JOIN dbo.variables  v  with(nolock) on (v.var_id = sv.var_id)  
   LEFT JOIN dbo.specifications  specs with(nolock) ON (specs.spec_id = v.spec_id)  
  WHERE sheet_desc = @SheetDesc  
  
  ORDER by sv.var_order  
/* Update @Data COHint */  
 UPDATE @Data  
  SET COHint1 = ' '   
  WHERE COHint1 IS NULL  
 UPDATE @Data  
  SET COHint2 = ' '   
  WHERE COHint2 IS NULL  
 UPDATE @Data  
  SET COHint3 = ' '   
  WHERE COHint3 IS NULL  
 UPDATE @Data  
  SET COHint4 = ' '   
  WHERE COHint4 IS NULL  
  
 UPDATE @Data  
  SET COHint = CoHint1 +' ' + CoHint2 + ' ' + COHint3 + ' ' + CoHint4  
/*Update Char_ID of @Data */  
 UPDATE dt  
   SET char_id = chars.char_ID  
  FROM @Data  DT  
   LEFT JOIN dbo.characteristics  chars with(nolock) ON (chars.prop_id = dt.prop_id)  
  WHERE char_desc = @CharDesc   
  
 UPDATE dt  
   SET char_id = chars.char_ID  
  FROM @Data  DT  
   LEFT JOIN dbo.characteristics  chars with(nolock) ON (chars.prop_id = dt.prop_id)  
  WHERE dt.char_id is null and chars.char_desc LIKE @CharDesc +'%'  
  
/*Update COStepName if NULL to Variable */  
 UPDATE @Data  
   SET COStepName = variable  
  WHERE COStepName IS NULL  
/* Update Setting of Data */  
 UPDATE dt  
   SET setting = target  
  FROM @Data  dt  
   LEFT JOIN dbo.active_specs aspecs with(nolock) ON (aspecs.spec_id = dt.spec_id AND aspecs.char_id = dt.char_id AND expiration_date IS NULL)  
  
ReturnData:  
-- SELECT *  
 SELECT variable,COPerson,COStepName,Setting,COHint  
  FROM @Data  
  ORDER BY var_order  
  
