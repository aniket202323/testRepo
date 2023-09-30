CREATE Procedure [dbo].[spBF_GetVariableData_TimeFrame]
@varid int,
@starttime Datetime = NULL,
@endtime Datetime = NULL
AS
DECLARE @ConvertedST  	  DateTime,
  	    	 @ConvertedET  	  DateTime,
 	  	 @DbTZ 	  	  	  nVarChar(200),
 	  	 @VarDesc 	  	  nVarChar(100)
IF EXISTS (
SELECT v.var_id
FROM Variables v WITH(NOLOCK) 
WHERE v.var_id = @varid)
BEGIN
 	 SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@starttime,'UTC')
 	 SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endtime,'UTC')
 	 SELECT @DbTZ = value from site_parameters where parm_id=192
 	 --converting output timestamp to UTC from DB timezone 
 	 SELECT @VarDesc = Var_Desc FROM Variables Where Var_Id = @varid
 	 SELECT t.var_id, @VarDesc,dbo.fnServer_CmnConvertTime(t.Result_on,@DbTZ,'UTC') , t.Result
 	 FROM  Tests t WITH(NOLOCK)
 	 WHERE t.var_id = @varid AND t.Result_On BETWEEN @ConvertedST AND @ConvertedET
END
ELSE
BEGIN
-- Returning -999 when the entered Input ID is not present in DB
 	 SELECT -999, null, null, null
END
