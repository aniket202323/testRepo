   /*  
Stored Procedure: spLocal_GetProfileFunction  
Author:   Fran Osorno  
Date Created:  Oct 25, 2005  
  
Description:  
=========  
Calculates the MIN,MAX,AVG or the Range of a set of numbers from the calc dep variables  for a manual profile.  
  
Change Date Who What  
=========== ==== =====  
Oct. 25, 2005 FGO Created procedure  
*/  
CREATE PROCEDURE dbo.spLocal_GetProfileFunction  
 @Output_Value  VARCHAR(25) OUTPUT,  
 @Var_Id  INT,  
 @TimeStamp  DATETIME,  
 @Function  VARCHAR(50)  
AS  
  
/************************************************************************************************  
*                                                                                               *  
*                                 Global execution switches                                     *  
*                                                                                               *  
************************************************************************************************/  
 SET NOCOUNT ON  
 SET ANSI_WARNINGS OFF  
/************************************************************************************************  
*                                                                                               *  
*                                 Declare Variables      *  
*                                                                                               *  
************************************************************************************************/  
  
 DECLARE  
   @Count  INT,  
   @Total  REAL  
 DECLARE @Profile  TABLE(  
   Result FLOAT  
  )  
  
INSERT INTO @Profile (Result)  
SELECT CONVERT(FLOAT, t.Result)  
 FROM Calculation_Instance_Dependencies cid  
  INNER JOIN tests AS t ON t.Var_Id = cid.Var_Id   
 WHERE cid.Result_Var_Id = @Var_Id AND t.Result_On = @TimeStamp AND t.Result IS NOT NULL  
  
IF UPPER(@Function) = 'MIN'  
 BEGIN  
  SELECT @Output_Value = CONVERT(VARCHAR(25), MIN(Result))  
   FROM @Profile  
  GOTO ReturnPlantApps  
 END  
  
IF UPPER(@Function) = 'MAX'  
 BEGIN  
  SELECT @Output_Value = CONVERT(VARCHAR(25), MAX(Result))  
   FROM @Profile  
  GOTO ReturnPlantApps  
 END  
IF UPPER(@Function) = 'AVG'  
 BEGIN  
  SELECT  @Count = COUNT(result) FROM @Profile  
  WHERE RESULT >0  
  SELECT @Total = SUM(result) FROM @Profile  
  SELECT @Output_Value = @Total/@Count  
  GOTO ReturnPlantApps  
 END  
IF UPPER(@Function) = 'RANGE'  
 BEGIN  
  SELECT @Output_Value = CONVERT(VARCHAR(25), MAX(Result) - MIN(Result))  
   FROM @Profile  
  GOTO ReturnPlantApps  
 END  
  
  
ReturnPlantApps:  
