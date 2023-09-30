CREATE PROCEDURE DBO.spCSS_SPUpdateStats
@SPName nvarchar(50), 
@ExecCount int, 
@ExecMinMS int,
@ExecMaxMS int,
@ExecTotalSec float,
@TimeoutCount tinyint,
@DeadlockCount tinyint
AS
Select @ExecMinMS = isnull(@ExecMinMS,0)
Select @ExecMaxMS = isnull(@ExecMaxMS,0)
Update Client_SP_Prototypes
  SET ExecCount = ExecCount + @ExecCount, 
   ExecTotalMinutes = ExecTotalMinutes + (@ExecTotalSec / 60),
   TimeoutCount = TimeoutCount + @TimeoutCount, 
   DeadlockCount = DeadlockCount + @DeadlockCount
  WHERE SP_Name = @SPName
If @ExecMinMS > 0 
 	 Update Client_SP_Prototypes
   	 SET ExecMinMS = @ExecMinMS
  	  WHERE SP_Name = @SPName and (@ExecMinMS < ExecMinMS)
If @ExecMaxMS > 0
 	 Update Client_SP_Prototypes
  	  SET ExecMaxMS = @ExecMaxMS
   	 WHERE SP_Name = @SPName and (@ExecMaxMS > ExecMaxMS)
Return(1)
