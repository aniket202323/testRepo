Create Procedure dbo.spEX_GetRunningProduct
@pPU_Id int,
@pStart_Time datetime,
@pProd_Id int OUTPUT,
@pProd_Code nvarchar(100) OUTPUT
AS
select @pProd_Id = p.Prod_Id, @pProd_Code = r.Prod_Code 
from PRODUCTION_STARTS P WITH (NOLOCK)
Join PRODUCTS R on R.Prod_ID = P.Prod_ID
Where P.PU_Id = @pPU_Id and 
      @pStart_Time >= P.Start_Time and 
     (P.End_Time is null OR @pStart_Time <= P.End_Time)
RETURN(100)
