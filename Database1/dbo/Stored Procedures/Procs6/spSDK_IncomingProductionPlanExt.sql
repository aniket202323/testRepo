CREATE PROCEDURE dbo.spSDK_IncomingProductionPlanExt
 	 @PPId 	  	  	  	  	 INT,
 	 @UserGeneral1 	  	 nvarchar(255) 	 = NULL,
 	 @UserGeneral2 	  	 nvarchar(255) 	 = NULL,
 	 @UserGeneral3 	  	 nvarchar(255) 	 = NULL,
 	 @ExtendedInfo 	  	 nvarchar(255) 	 = NULL
AS
-------------------------------------------------------------------------------
-- Check if Process Order exists
-------------------------------------------------------------------------------
IF 	 (SELECT 	 Count(PP_Id)
 	  	 FROM 	 Production_Plan
 	  	 WHERE 	 PP_Id 	 = @PPId) = 0
BEGIN
 	 RETURN(1)
END
-------------------------------------------------------------------------------
-- Update User General Fields
-------------------------------------------------------------------------------
UPDATE 	 Production_Plan
 	 SET 	 User_General_1 	 = COALESCE(@UserGeneral1, User_General_1),
 	  	  	 User_General_2 	 = COALESCE(@UserGeneral2, User_General_2),
 	  	  	 User_General_3 	 = COALESCE(@UserGeneral3, User_General_3),
 	  	  	 Extended_Info 	 = COALESCE(@ExtendedInfo, Extended_Info)
 	 WHERE 	 PP_Id 	 = @PPId
RETURN(0)
