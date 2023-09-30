/**
 * <summary>
 * Updates the calling statistics for the various stored
 * procedures.
 * </summary>
 * <returns>
 * Always retuns 1.
 * </returns>
 * <remarks>
 * This is used by the PDB.NET API to update the columns in
 * <c>Client_SP_Prototypes</c> that reflect the statistics about
 * how the specified procedure was called.
 * </remarks>
 */
CREATE PROCEDURE DBO.spPDB_SPUpdateStats
@SPName nVarchar(50), /** The stored procedure whose stats are being updated. */
@ExecCount int, /** How many times the SP was called. */
@ExecMinMS int, /** The minimum execution time (milliseconds) during those calls. */
@ExecMaxMS int, /** The maximum execution time (milliseconds) during those calls. */
@ExecTotalSec float, /** The total amount of execution time (seconds) for all those calls. */
@TimeoutCount tinyint, /** How many times calling the SP timed out. */
@DeadlockCount tinyint /** How many times calling the SP resulted in a deadlock. */
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
  	  WHERE SP_Name = @SPName and (@ExecMinMS < ExecMinMS OR ExecMinMS = 0)
If @ExecMaxMS > 0
 	 Update Client_SP_Prototypes
  	  SET ExecMaxMS = @ExecMaxMS
   	 WHERE SP_Name = @SPName and (@ExecMaxMS > ExecMaxMS)
Return(1)
