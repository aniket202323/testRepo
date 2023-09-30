  
-- Stored Procedure: spLocal_ProcessOrderQuantityStatus  
-- Created By:  Dan Hinchey (GE Fanuc - Mountain Systems)  
-- Created Date: December 23, 2003  
--  
-- This SP calculates the percent completion of the current 'Active' Process Order.  
-- If there is no 'Active' Process Order then the value is set to zero.  
-- The variable used as an input to this SP must be configured using a Sampling Type  
-- of 'Increase'.  
--  
CREATE PROCEDURE dbo.spLocal_ProcessOrderQuantityStatus  
 @OutPut_Value VarChar(25) OUTPUT,  
--declare  
-- @OutPut_Value VarChar(25),  
 @MaterPU_Id Int,  
 @Var_Id  Int,  
 @TimeStamp DateTime,  
 @Prod_Var_Id Int  
AS  
  
-- Test Inputs  
/*  
select  
 @MaterPU_Id = 534,  
 @Var_Id  = 24991,  
 @TimeStamp = getdate(),  
 @Prod_Var_Id = 215121  
*/  
  
-- Declare Local Variables.  
DECLARE @PP_Id   Int,  
 @Target_Prod  Float,  
 @Actual_Prod  Float,  
 @Percent_Complete Float  
-- Get the Active Production Plan ID and Forecast Quantity.  
SELECT @PP_Id = pps.PP_Id, @Target_Prod = Forecast_Quantity  
 FROM Production_Plan_Starts pps  
 JOIN Production_Plan pp ON pps.PP_Id = pp.PP_Id  
 WHERE pps.PU_Id = @MaterPU_Id  
 AND Start_Time < @TimeStamp  
 AND (End_Time >= @TimeStamp OR End_Time IS NULL)  
-- If there is no active Production Plan then set percent complete to zero,  
-- otherwise calculate percent complete.  
IF @PP_Id IS NOT NULL  
BEGIN  
 -- Get the total quantity produced for all 'Active' periods of the Process Order.  
 SELECT @Actual_Prod = SUM(CONVERT(FLOAT, COALESCE(convert(float,t.Result),0)))  
  FROM Tests t  
  JOIN Production_Plan_Starts pps ON t.Result_On >= pps.Start_Time  
  AND (t.Result_On <= pps.End_Time OR pps.End_Time IS NULL)  
  AND t.Result_On <= @TimeStamp  
  AND t.Var_Id = @Prod_Var_Id  
  AND pps.PP_Id = @PP_Id  
  AND pps.PU_Id = @MaterPU_Id -- Added by DJM and STP 2007-11-05  
 WHERE t.result is not null -- Added by EP 2007-06-06  
 SELECT @Percent_Complete = COALESCE((@Actual_Prod / @Target_Prod) * 100,0)  
END  
ELSE  
BEGIN  
 SELECT @Percent_Complete = 0  
END  
SELECT @OutPut_Value = @Percent_Complete  
--select @output_value  
