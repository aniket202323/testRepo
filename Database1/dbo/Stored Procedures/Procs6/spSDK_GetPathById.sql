CREATE PROCEDURE dbo.spSDK_GetPathById
 	 @PathId 	  	  	  	  	 INT
AS
IF @PathId = 0 
   SELECT PathId = 0, PathCode = ''
ELSE
 	 SELECT PathId = Path_Id,
 	  	  	  PathCode = Path_Code
 	 FROM PrdExec_Paths
 	 WHERE Path_Id = @PathId
