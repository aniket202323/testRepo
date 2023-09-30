CREATE PROCEDURE dbo.spSDK_GetCharacteristicId
 	 @PropId 	  	  	 INT,
 	 @CharDesc 	  	 nvarchar(100),
 	 @CharId 	  	  	 INT 	  	  	  	 OUTPUT
AS
IF (SELECT COUNT(*) FROM Product_Properties WHERE Prop_Id = @PropId) = 0
BEGIN
 	 RETURN(1)
END
SELECT 	 @CharId = NULL
SELECT 	 @CharId = Char_Id
 	 FROM 	 Characteristics
 	 WHERE 	 Prop_Id = @PropId AND
 	  	  	 Char_Desc = @CharDesc
IF @CharId IS NULL
BEGIN
 	 RETURN(2)
END
RETURN(0)
