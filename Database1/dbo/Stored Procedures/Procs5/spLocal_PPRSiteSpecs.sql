  /*  
Stored Procedure: spLocal_PPRSiteSpecs  
Author:   Fran Osorno  
Date Created: 04/11/06  
  
Description:  
=========  
This procedure will report all specs for perfect parent roll  
  
calls:  
  
GBDB.dbo.fnlocal_GlblParseInfoWithSpaces  
  
Change Date Who  What  
======== ==== =====  
04/11/06  fgo  created  
05/18/06  fgo  total rewrite  
*/  
CREATE                 PROCEDURE dbo.spLocal_PPRSiteSpecs  
/* Declare sp variables */  
-- DECLARE  
   @Start  datetime,  
   @End  datetime  
/* set the sp varialbes */  
-- SELECT @Start = '1/1/2000', @End = '1/1/2000'  
AS  
/*declare the Local variables */  
 DECLARE  
   @PUGDesc  varchar(50),  --the pug_desc to look in  
   @PUDesc  varchar(50),  --the pu_desc to look in  
   @VarDesc  varchar(50),  --the var_desc to look for  
   @PropDesc varchar(50),  --the prop_desc to look for  
   @PGDesc  varchar(50),  --the product group desc to look for  
    @LinkStr1  varchar(100),  --the PPRNot1 variable  
   @LinkStr2  varchar(100),  --the PPRNot2 variable  
   @LinkStr3  varchar(100),  --the PPR1 variable  
   @LinkStr4  varchar(100)  --the PPR2 variable  
  
DECLARE @RawData TABLE(     --the raw product data  
  prop_id  int,     --this is the prop_id  
  char_desc  varchar(50),   --this is the char_desc  
  char_id  int,     --this is the char_id  
  pu_id  int,     --this is the pu_id  
  prod_id  int,     --this is the prod_id  
  pg_id  int,     --this is the prodcut_group_id  
  PG_Desc  varchar(50),   -- the product group desc  
  PPRNot1  varchar(100),   --this is the first PPR variable not to use  
  PPRNot2  varchar(100),   --this is the second PPR variable not to use  
  PPR1   varchar(100),   --this is the first PPR variable to use  
  PPR2   varchar(100)   --this is the second PPR variable to use  
 )  
  
 DECLARE @Data TABLE(     --the data table  
   Line      varchar(50), --this is the line  
   variable     varchar(50), --this is the variable  
   char_id     int,   --this is the char_id  
   char_desc     varchar(50), --this is the char_desc  
   pu_id     int,   --this is the pu_id  
   prop_desc     varchar(50), --this is the prop_desc to verify for Global Items  
   prod_id     int,   --this is the product ID  
   attribute     int,   --this is an attribute variable 1= attribute  
   [Report]     int,   --this is the Report Flag 1 = Yes 0 = No  
   [Effective Date]    datetime,  --the effective date  
   [Expiration Date]   datetime,  --the expiration date  
   [Lower Hold/Reject Limit]  varchar(25), --LRL  
   [Lower Flagged Limit]   varchar(25), --LWL  
   [Perfect]      varchar(25), --target  
   [Upper Flagged Limit]  varchar(25), --UWL  
   [Upper Hold/Reject Limit]  varchar(25) --URL  
  
  )  
 DECLARE @DataGlobal TABLE(     --the data table for the Global Items Property  
   Line      varchar(50), --this is the line  
   variable     varchar(50), --this is the variable  
   spec_id     int,   --this is the spec_id  
   char_id     int,   --this is the char_id  
   char_desc     varchar(50), --this is the char_desc  
   pu_id     int,   --this is the pu_id  
   prod_id     int,   --this is the prod ID  
   prop_desc     varchar(50), --this is the prop_desc to verify for Global Items  
   attribute     int,   --this is an attribute variable 1= attribute  
   [Report]     int,   --this is the Report Flag 1 = Yes 0 = No  
   [Effective Date]    datetime,  --the effective date  
   [Expiration Date]   datetime,  --the expiration date  
   [Lower Hold/Reject Limit]  varchar(25), --LRL  
   [Lower Flagged Limit]   varchar(25), --LWL  
   [Perfect]      varchar(25), --target  
   [Upper Flagged Limit]  varchar(25), --UWL  
   [Upper Hold/Reject Limit]  varchar(25) --URL  
  
  )  
  
/* set the local variables */  
 SELECT @PUGDesc = 'Perfect Parent Roll',@PUDesc = '%Rolls', @VarDesc = 'Perfect Parent Roll Status',  
  @LinkStr1 = 'PPRNot1=',@LinkStr2 ='PPRNot2=',@LinkStr3 ='PPR1=',@LinkStr4 ='PPR2=',  
  @PropDesc = '% Paper Quality',@PGDesc = '%PPR'  
/*fill @RawData */  
INSERT INTO @RawData(char_desc,prop_id,char_id,pu_id,prod_id,pg_id,PG_Desc)  
 SELECT c.char_desc,pp.prop_id,c.char_id,pu.pu_id,p.prod_id,pg.product_grp_id,pg.product_grp_desc  
  FROM dbo.characteristics c   
   LEFT JOIN dbo.product_properties pp ON pp.prop_id = c.prop_id  
   LEFT JOIN dbo.pu_characteristics puc ON puc.char_id = c.char_id and puc.prop_id = pp.prop_id  
   LEFT JOIN dbo.prod_units pu ON pu.pu_id = puc.pu_id  
   LEFT JOIN dbo.products p ON p.prod_id = puc.prod_id  
   LEFT JOIN dbo.product_group_data pgd ON pgd.prod_id = p.prod_id  
   JOIN dbo.product_groups pg ON pg.product_grp_id = pgd.product_grp_id  
  WHERE pp.prop_desc like @PropDesc  
   and pu.pu_desc like @PUDesc  
   and pg.product_grp_desc like @PGDesc  
/* update @RawData */  
UPDATE rd  
  SET PPRNot1 = GBDB.dbo.fnLocal_GlblParseInfoWithSpaces (pg1.External_Link,@LinkStr1),  
   PPRNot2 = GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg2.External_Link,@LinkStr2),  
   PPR1 = GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg3.External_Link,@LinkStr3),  
   PPR2 = GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg4.External_Link,@LinkStr4)  
 FROM @RawData rd  
  LEFT JOIN dbo.product_groups pg1 ON pg1.product_grp_id = rd.pg_id and GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg1.External_Link,@LinkStr1)IS not null  
  LEFT JOIN dbo.product_groups pg2 ON pg2.product_grp_id = rd.pg_id and GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg2.External_Link,@LinkStr2)IS not null  
  LEFT JOIN dbo.product_groups pg3 ON pg3.product_grp_id = rd.pg_id and GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg3.External_Link,@LinkStr3)IS not null  
  LEFT JOIN dbo.product_groups pg4 ON pg4.product_grp_id = rd.pg_id and GBDB.dbo.fnlocal_GlblParseInfoWithSpaces(pg4.External_Link,@LinkStr4)IS not null  
  
/* get all the variables for the site for @data */  
IF @Start <>'1/1/2000' and @end<> '1/1/2000'  
BEGIN  
 INSERT INTO @Data(Line,variable,pu_id,char_id,char_desc,prop_desc,prod_id,attribute,  
   [Effective Date],[Expiration Date],[Lower Hold/Reject Limit],  
   [Lower Flagged Limit],[Perfect], [Upper Flagged Limit],  
    [Upper Hold/Reject Limit])  
 SELECT pl.pl_desc,v.var_desc,v.pu_id,chars.char_id,chars.char_desc,pp.prop_desc,puc.prod_id,  
   CASE   
    WHEN dt.user_defined = 0  THEN 0  
    ELSE 1  
   END,  
   aspecs.effective_date,aspecs.expiration_date,  
   CASE  
    WHEN aspecs.L_Reject IS not null THEN aspecs.L_Reject  
    ELSE ' Not Set'  
   END,  
   CASE  
    WHEN aspecs.L_Warning IS not null THEN aspecs.L_Warning  
    ELSE 'Not Set'  
    END,  
   CASE  
    WHEN aspecs.Target IS not null THEN aspecs.Target  
    ELSE 'Not Set'  
   END,  
    CASE  
    WHEN aspecs.U_Warning IS not Null THEN aspecs.U_Warning  
    ELSE 'Not Set'  
   END,  
    CASE  
    WHEN aspecs.U_Reject IS not null THen aspecs.U_Reject  
    ELSE 'Not Set'  
   END  
  
  FROM dbo.Calculation_Instance_Dependencies CID  
   JOIN dbo.variables v ON v.var_id = cid.var_id  
   JOIN dbo.variables v1 ON v1.var_id = cid.result_var_id  
   JOIN dbo.pu_groups pug ON pug.pug_id = v.pug_id  
   JOIN dbo.prod_units pu ON pu.pu_id = v.pu_id  
   JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id  
   JOIN dbo.data_type dt ON dt.data_type_id = v.data_type_id  
   LEFT JOIN dbo.specifications specs ON specs.spec_id = v.spec_id  
   LEFT JOIN dbo.product_properties pp ON pp.prop_id = specs.prop_id  
   LEFT JOIN dbo.characteristics chars ON chars.prop_id = pp.prop_id  
   LEFT JOIN dbo.active_specs aspecs ON  aspecs.spec_id= v.spec_id and aspecs.char_id = chars.char_id   
   LEFT JOIN dbo.pu_characteristics puc ON puc.pu_id = v.pu_id and puc.prop_id = pp.prop_id and puc.char_id = chars.char_id  
  
  WHERE cid.Calc_Dependency_NotActive = 0 and  
   pu.pu_desc like @PUDesc and  
   v.var_desc <> @VarDesc and  
   v.spec_id is not null and  
   v1.var_desc = @VarDesc  
   and (aspecs.effective_date >= @Start and (aspecs.expiration_date <= @End  or aspecs.expiration_date is null))  
END  
IF @Start ='1/1/2000' and @end= '1/1/2000'  
BEGIN  
 INSERT INTO @Data(Line,variable,pu_id,char_id,char_desc,prop_desc,prod_id,attribute,  
   [Effective Date],[Expiration Date],[Lower Hold/Reject Limit],  
   [Lower Flagged Limit],[Perfect], [Upper Flagged Limit],  
    [Upper Hold/Reject Limit])  
 SELECT pl.pl_desc,v.var_desc,v.pu_id,chars.char_id,chars.char_desc,pp.prop_desc,puc.prod_id,  
   CASE   
    WHEN dt.user_defined = 0  THEN 0  
    ELSE 1  
   END,  
   aspecs.effective_date,aspecs.expiration_date,  
   CASE  
    WHEN aspecs.L_Reject IS not null THEN aspecs.L_Reject  
    ELSE ' Not Set'  
   END,  
   CASE  
    WHEN aspecs.L_Warning IS not null THEN aspecs.L_Warning  
    ELSE 'Not Set'  
    END,  
   CASE  
    WHEN aspecs.Target IS not null THEN aspecs.Target  
    ELSE 'Not Set'  
   END,  
    CASE  
    WHEN aspecs.U_Warning IS not Null THEN aspecs.U_Warning  
    ELSE 'Not Set'  
   END,  
    CASE  
    WHEN aspecs.U_Reject IS not null THen aspecs.U_Reject  
    ELSE 'Not Set'  
   END  
  
  FROM dbo.Calculation_Instance_Dependencies CID  
   JOIN dbo.variables v ON v.var_id = cid.var_id  
   JOIN dbo.variables v1 ON v1.var_id = cid.result_var_id  
   JOIN dbo.pu_groups pug ON pug.pug_id = v.pug_id  
   JOIN dbo.prod_units pu ON pu.pu_id = v.pu_id  
   JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id  
   JOIN dbo.data_type dt ON dt.data_type_id = v.data_type_id  
   LEFT JOIN dbo.specifications specs ON specs.spec_id = v.spec_id  
   LEFT JOIN dbo.product_properties pp ON pp.prop_id = specs.prop_id  
   LEFT JOIN dbo.characteristics chars ON chars.prop_id = pp.prop_id  
   LEFT JOIN dbo.active_specs aspecs ON  aspecs.spec_id= v.spec_id and aspecs.char_id = chars.char_id   
   LEFT JOIN dbo.pu_characteristics puc ON puc.pu_id = v.pu_id and puc.prop_id = pp.prop_id and puc.char_id = chars.char_id  
  
  WHERE cid.Calc_Dependency_NotActive = 0 and  
   pu.pu_desc like @PUDesc and  
   v.var_desc <> @VarDesc and  
   v.spec_id is not null and  
   v1.var_desc = @VarDesc  
   and aspecs.expiration_date is null  
END  
  
DELETE @Data WHERE prod_id is NULL  
  
/* put all the global items in @DataGlobal */  
 INSERT INTO @DataGlobal(Line,variable,char_desc,attribute,pu_id,prod_id,  
    [Report],[Effective Date],[Expiration Date],[Lower Hold/Reject Limit],[Lower Flagged Limit],  
    [Perfect],[Upper Flagged Limit], [Upper Hold/Reject Limit])  
  SELECT line,variable,rd.char_desc,attribute,d.pu_id,d.prod_id,report,[Effective Date],[Expiration Date],[Lower Hold/Reject Limit],[Lower Flagged Limit],  
    [Perfect],[Upper Flagged Limit], [Upper Hold/Reject Limit]  
   FROM @data d  
    LEFT JOIN @Rawdata rd on rd.prod_id = d.prod_id and rd.pu_id = d.pu_id   
   WHERE d.prop_desc = 'Global Items'  
  
  
  
/* remove all the Global Items Property Characteristics from @Data */  
 DELETE @Data WHERE prop_desc = 'Global Items'  
  
/* Getting all the data in @DataGlobal set up for all the Characteristics in @RawData */  
 INSERT INTO @Data(Line,variable,char_desc,attribute,pu_id,prod_id,  
    [Report],[Effective Date],[Expiration Date],[Lower Hold/Reject Limit],[Lower Flagged Limit],  
    [Perfect],[Upper Flagged Limit], [Upper Hold/Reject Limit])  
  SELECT line,variable,char_desc,attribute,pu_id,prod_id,report,[Effective Date],[Expiration Date],[Lower Hold/Reject Limit],[Lower Flagged Limit],  
    [Perfect],[Upper Flagged Limit], [Upper Hold/Reject Limit]  
 FROM @DataGlobal dg  
  
  
/* Update Report of @Data for the Not Variables */  
UPDATE d  
 SET Report = case  
  WHEN d.variable like '%'+  rd.PPRNot1 + '%' and len(rd.PPRNot1) >0 THEN 0  
  WHEN d.variable like '%'+  rd.PPRNot2 + '%' and len(rd.PPRNot2) >0  THEN 0  
  WHEN d.attribute =0 and (d.variable not like '%'+  rd.PPRNot1 + ' %') THEN 1  
  WHEN d.attribute =0 and (d.variable not like '%'+  rd.PPRNot2 + ' %') THEN 1  
  WHEN d.attribute =1 and (d.variable not like '%'+  rd.PPRNot1 + ' %') THEN 1  
  WHEN d.attribute =1 and (d.variable not like '%'+  rd.PPRNot2 + ' %') THEN 1  
  WHEN (d.variable like '% Sheetbreak %' or d.variable like '% Official')  THEN 1   
  ELSE  
   d.report  
  END  
 FROM @Data d  
  LEFT JOIN @Rawdata rd on rd.prod_id = d.prod_id and rd.pu_id = d.pu_id  
UPDATE d  
 SET Report = case  
   WHEN (d.variable like '%' + rd.ppr1 + '%' and rd.ppr1 is not null) and d.report is null Then 1  
   WHEN (d.variable not like '%' + rd.ppr1 + '%' and rd.ppr1 is not null) and d.report is null Then 0  
   ELSE  
     d.report  
  END  
 FROM @Data d  
  LEFT JOIN @Rawdata rd on rd.prod_id = d.prod_id and rd.pu_id = d.pu_id   
  
UPDATE d  
 SET Report = case  
   WHEN (d.variable like '%' + rd.ppr2 + '%' and len(rd.ppr2)>0) and d.report is null and d.attribute = 0 Then 1  
   ELSE  
    d.report  
  END  
 FROM @Data d  
  LEFT JOIN @Rawdata rd on rd.prod_id = d.prod_id and rd.pu_id = d.pu_id   
  
ReturnPlantApps:  
SELECT Line,char_desc AS [Product Type],variable,[Effective Date],[Expiration Date],  
  [Lower Hold/Reject Limit], [Lower Flagged Limit],[Perfect],[Upper Flagged Limit],  
  [Upper Hold/Reject Limit]  
 FROM @Data  
 WHERE [Report] = 1  
 ORDER by Line,char_desc,variable, [Effective Date]  
    
SET QUOTED_IDENTIFIER OFF   
