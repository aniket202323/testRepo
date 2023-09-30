 /*  
Stored Procedure: spLocal_GetLastValueEntered  
Author:   Fran Osorno  
Date Created:  April 6, 2006  
  
Description:  
=========  
This function will return the top value entered in the trest table for the varaible that does not a have a timestamp greater than  
 the time stamp of the variable in question  
  
 @OutputValue  varchar(25) OUTPUT  the outputed results    
 @VarId   int     the variaible in question for the result  
 @TimeStamp  datetime    the time or the result,  
      
  
Change Date  Who  What  
=========== ==== =====  
4/6/2006   FGO  Created procedure  
*/  
  
CREATE PROCEDURE dbo.spLocal_GetLastValueEntered  
  
 @OutputValue  varchar(25) OUTPUT,  
 @VarId   int,  
 @TimeStamp  datetime  
as  
/*   
-- TESTING Stuff  
 DECLARE  
  @OutputValue  varchar(25),-- OUTPUT,  
  @VarId   INT,  
  @TimeStamp  DATETIME,  
 select @varid = 4463,@timestamp = '1/26/06 12:58:47'  
*/  
/****************************/  
/*     Global execution switches       */   
/****************************/  
 SET NOCOUNT ON  
 SET ANSI_WARNINGS OFF  
  
/************************/  
/* Declare Variables      */  
/************************/  
  
/************************/  
/* Do the Function       */  
/************************/  
select top 1 @OutputValue= result  
 from dbo.tests  
 where var_id = @VarId and result_on <= @TimeStamp  
 order by result_on desc  
  
/***********************/  
/*              Return     */  
/***********************/  
  
ReturnPlantApps:  
