   /*  
Stored Procedure: spLocal_GetSummaryResult  
Author:   Fran Osorno  
Date Created:  Jan 26, 2006  
  
Description:  
=========  
Calculates the MIN, MAX, AVG, RANGE, STDEV  or SUM of a set of numbers from the calc dep variables for a give variable.  
  
 @OutputValue  varchar(25) OUTPUT  the outputed results    
 @VarId   int     the variaible in question for the result  
 @TimeStamp  datetime    the time or the result,  
 @Function   varchar(50)   the function MIN, MAX, AVG, RANGE, STDEV  or SUM  
 @OverRide  int     the override  
           if 9999 then no over ride and the result will be posted to the test and test_history table on every dep variable change  
           if = 0 all dep variables must be in the test table before the calc will return a result  
           if any int value other then 9999 and 0 then the result will return a result  after that many dep variables are in the test table  
 @CheckVar  varchar(25)   this is the var_id of a variable to check that data is in the test table before friing this calc.  
           it can also be 0  then the calc will proceed.  
      
  
Change Date  Who  What  
=========== ==== =====  
Jan 26, 2006  FGO  Created procedure  
April 6, 2006  FGO  Added a CheckVar  
April 7, 2006  FGO   modified to handle auto entry data and an extra dependent variable; this uses the User_defined1 field of dbo.variables  
      If the variable is not to be used in the calculation  
July 6, 2006  FGO  Modified the code to handle the case when more that the @OverRide number of values are entered.  In this case the data will not  
      be written to the database until all the dependent variables have been entered  
*/  
  
CREATE    PROCEDURE dbo.spLocal_GetSummaryResult  
--declare  
 @OutputValue  varchar(25) OUTPUT,  
 @VarId   int,  
 @TimeStamp  datetime,  
 @Function   varchar(50),  
 @OverRide  int,  
 @CheckVar  int  
AS  
  
-- TESTING Stuff  
  
-- select @varid = 11906,@timestamp = '07/02/06 23:30:44', @function ='AVG', @OverRide =8, @CheckVar = '0'  
  
/*     Global execution switches        */   
  
 SET NOCOUNT ON  
 SET ANSI_WARNINGS OFF  
  
  
/* Declare Variables      */  
  
 DECLARE  
   @count  int,  
   @Total  real,  
   @Depcount int  
  
 DECLARE @Profile  TABLE(  
   Result float,  
   ToUse varchar(10)  
  )  
  
  
/*      Fill @Profile                     */  
/* Testing */  
 --select @OutputValue = 'Nothing Done'  
/* the the state of @CheckVar */  
 IF upper(@CheckVar) = '0' GOTO ContinueCode  
 IF upper(@CheckVar) <> '0'   
  BEGIN  
   IF EXISTS(SELECT * FROM dbo.tests WHERE var_id = convert(int,@CheckVar) and result_on = @TimeStamp and result is not null)  
    BEGIN  
     GOTO ContinueCode  
    END  
   ELSE  
    GOTO ReturnPlantApps       
  END       
ContinueCode:  
INSERT INTO @Profile (Result,ToUse)  
SELECT convert(float, t.Result),v.user_Defined1  
 FROM dbo.Calculation_Instance_Dependencies cid  
  INNER JOIN dbo.tests t on t.Var_Id = cid.Var_Id   
  INNER JOIN  dbo.variables v on v.var_id = t.var_id  
 WHERE cid.Result_Var_Id = @VarId AND t.Result_on = @TimeStamp and t.Result is not null  
  
  
  
/*            Check @OverRide     */  
/* if =9999 then proceed          */  
  
  
 IF @OverRide <> 9999  
  BEGIN  
  
   /*             Fill @Depcoun                  */  
  
    SELECT @Depcount = count(*)   
     FROM dbo.Calculation_Instance_Dependencies cid  
      LEFT JOIN dbo.variables v ON v.var_id =cid.var_id  
     WHERE cid.Result_Var_Id = @VarId and v.user_Defined1 is null  
  
   /* If 0 check count of                        */    
   /* @Profile> = @Depcount               */  
  
     IF @OverRide = 0  
      BEGIN  
       IF (SELECT count(*) FROM @Profile WHERE ToUse is null) < @Depcount GOTO ReturnPlantApps  
       GOTO StartFunction  
      END  
  
   /*             If 0 check count of           */  
   /*  @Profile> = @OveRride      */  
  
    IF @OverRide <> 0  
     BEGIN  
      IF(SELECT count(*) FROM  @Profile WHERE ToUse is null) < @OverRide GOTO ReturnPlantApps  
      IF(SELECT count(*) FROM @Profile WHERE ToUse is null) = @OverRide GOTO StartFunction  
      IF(SELECT count(*) FROM @Profile WHERE ToUse is null) >@OverRide GOTO CheckAgain  
CheckAgain:  
      IF(SELECT count(*) FROM @Profile WHERE ToUse is null) = @DepCount GOTO StartFunction  
      SELECT @OutputValue = 'DONOTHING'        
      GOTO ReturnPlantApps  
     END  
  END  
  
/* Check @Function                         */  
/*  and do the right Call      */  
  
StartFunction:  
IF upper(@Function) = 'MIN'  
 BEGIN  
  SELECT @OutputValue = convert(varchar(25), min(Result))  
   FROM @Profile  
   WHERE ToUse is null  
  GOTO ReturnPlantApps  
 END  
  
IF upper(@Function) = 'MAX'  
 BEGIN  
  SELECT @OutputValue = convert(varchar(25), max(Result))  
   FROM @Profile  
   WHERE ToUse is null  
  GOTO ReturnPlantApps  
 END  
IF upper(@Function) = 'AVG'  
 BEGIN  
  SELECT  @count = count(result) FROM @Profile WHERE ToUse is null and RESULT >0  
  SELECT @Total = sum(result) FROM @Profile WHERE ToUse is null  
  IF @Total = 0  
   BEGIN  
    SELECT @OutputValue = 'DONOTHING'  
    GOTO ReturnPlantApps  
   END  
  SELECT @OutputValue = convert(varchar(25),@Total/@count)  
  GOTO ReturnPlantApps  
 END  
IF upper(@Function) = 'RANGE'  
 BEGIN  
  SELECT @OutputValue = convert(varchar(25), max(Result) - min(Result))  
   FROM @Profile  
   WHERE ToUse is null  
  GOTO ReturnPlantApps  
 END  
IF upper(@Function) = 'SUM'  
 BEGIN  
  SELECT @OutputValue = convert(varchar(25), sum(Result))   
   FROM @Profile  
   WHERE ToUse is null  
  GOTO ReturnPlantApps  
 END  
  
IF upper(@Function) = 'STDDEV'  
 BEGIN  
  IF  (select convert(varchar(25), max(Result) - min(Result)) FROM @Profile WHERE ToUse is null) <=1  
   BEGIN  
    SELECT @OutputValue = 'DONOTHING'  
    GOTO ReturnPlantApps  
   END  
  SELECT @OutputValue = convert(varchar(25), stdev(Result))   
   FROM @Profile  
   WHERE ToUse is null  
  GOTO ReturnPlantApps  
 END  
  
  
/*              Return      */  
  
  
ReturnPlantApps:  
/* testing */  
-- select * from @Profile  
-- SELECT count(*) FROM  @Profile WHERE ToUse is null  
-- select @Depcount  
-- select @OutputValue  
-- select @CheckVar  
  
  
