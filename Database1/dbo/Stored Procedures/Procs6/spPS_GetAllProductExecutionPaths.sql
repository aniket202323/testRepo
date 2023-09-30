
CREATE PROCEDURE [dbo].[spPS_GetAllProductExecutionPaths]
@User_Id      int = 1

   AS
		BEGIN
			SELECT * FROM PrdExec_Paths
		END

	