CREATE PROCEDURE dbo.spSDK_GetSpecificationId
 	 @PropId 	  	  	 INT,
 	 @SpecDesc 	  	 nvarchar(100),
 	 @SpecId 	  	  	 INT 	  	  	  	 OUTPUT
AS
IF (SELECT COUNT(*) FROM Product_Properties WHERE Prop_Id = @PropId) = 0
BEGIN
 	 RETURN(1)
END
SELECT 	 @SpecId = NULL
SELECT 	 @SpecId = Spec_Id
 	 FROM 	 Specifications
 	 WHERE 	 Prop_Id = @PropId AND
 	  	  	 Spec_Desc = @SpecDesc
IF @SpecId IS NULL
BEGIN
 	 RETURN(2)
END
RETURN(0)
