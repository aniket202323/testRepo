-------------------------------------------------------------------------------
--
-- This Stored Procedure will retrieve a parameter value from a table that
-- is passed to the stored procedure as the TableId.
--
-- Date  	  Version  	 Build  	 Author 	  	 Comment
-- 09-Jan-2006   001            4.20    AlexJ 	  	 Initial coding
--
-------------------------------------------------------------------------------
CREATE 	 PROCEDURE dbo.spCmn_UDPLookupById
 	 @LookupValue  	  VARCHAR(1000)  	  OUTPUT,
 	 @TableId  	  INT,
 	 @KeyId 	  	  INT,
 	 @PropertyId  	  INT,
 	 @DefaultValue  	  VARCHAR(1000) = NULL
AS 
SELECT 	 @LookupValue  	 = @defaultvalue
-------------------------------------------------------------------------------
-- Retrieve the parameter value for the passed TableId, KeyId and Parameter Name
-------------------------------------------------------------------------------
SELECT 	 @LookupValue 	  	  	 = TFV.Value
 	 FROM 	 dbo.Table_Fields_Values TFV
 	 WHERE 	 TFV.TableId 	  	 = @TableId
 	 AND 	 TFV.KeyId 	  	 = @KeyId
 	 AND 	 TFV.Table_Field_Id 	 = @PropertyId
RETURN
