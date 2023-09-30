-------------------------------------------------------------------------------
-- This Stored Procedure will retrieve a parameter value from a table that
-- is passed to the stored procedure as the TableId.
--
-- Date  	  Version  	 Build  	 Author 	  	 Comment
-- 25-Feb-2005  	  001  	   	 4.11 	 SharonR  	 Initial coding.
--
-------------------------------------------------------------------------------
CREATE 	 PROCEDURE dbo.spCmn_UDPLookup
 	 @LookupValue  	  VARCHAR(1000)  	  OUTPUT,
 	 @TableId  	  INT,
 	 @KeyId 	  	  INT,
 	 @PropertyName  	  VARCHAR(255),
 	 @DefaultValue  	  VARCHAR(1000) = NULL
AS 
SELECT 	 @LookupValue  	 = @defaultvalue
-------------------------------------------------------------------------------
-- Retrieve the parameter value for the passed TableId, KeyId and Parameter Name
-------------------------------------------------------------------------------
SELECT  	 @LookupValue = tfv.Value
  	 FROM  	 Table_Fields_Values tfv
 	 JOIN 	 Table_Fields tf 	 ON tf.Table_Field_Id = tfv.Table_Field_Id
 	 JOIN 	 Tables t ON 	 t.TableID = tfv.TableID
 	  	 WHERE t.TableId = @TableId 
 	  	  	 AND tf.Table_Field_Desc = @PropertyName
 	  	  	  	 AND tfv.KeyId = @KeyID 
RETURN
