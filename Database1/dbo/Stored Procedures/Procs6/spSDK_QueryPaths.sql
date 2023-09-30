CREATE PROCEDURE dbo.spSDK_QueryPaths
 	 @LineMask 	  	 nvarchar(50) = NULL,
 	 @UserId 	  	  	 INT  	  	  	  	  = NULL
AS
SET 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SET 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT PathId = pep.Path_Id,
 	  	  	 PathCode = pep.Path_Code
 	 FROM PrdExec_Paths pep
  Join Prod_Lines pl on pl.PL_Id = pep.PL_Id
 	 WHERE 	 pl.PL_Desc LIKE @LineMask
 	 ORDER BY pep.Path_Code
