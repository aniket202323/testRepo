CREATE PROCEDURE dbo.spSDK_GetPropertyId
 	 @Property 	  	 nvarchar(100),
 	 @PropId 	  	  	 INT 	  	  	  	 OUTPUT
AS
SELECT 	 @PropId = NULL
SELECT 	 @PropId = Prop_Id
 	 FROM 	 Product_Properties
 	 WHERE 	 Prop_Desc = @Property
IF @PropId IS NULL
BEGIN
 	 RETURN(1)
END
RETURN(0)
