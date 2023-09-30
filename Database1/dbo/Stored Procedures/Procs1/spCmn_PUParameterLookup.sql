-------------------------------------------------------------------------------
-- This Stored Procedure will retrieve a parameter value associated with a 
--Production Unit.
-- It may be called several times by event model SPs to return values that would 
-- otherwise have been hard-coded into the SPs.
--
-- Date         Version Build Author  
-- 15-Jan-2004  001     001   AlexJ  Initial Coding
--
-- declare @Result varchar(255)
-- exec spcmn_PUParameterLookup @Result Output, 74, 'S88 Movement Source', 'xxx'
-- select @Result
--
-------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spCmn_PUParameterLookup
 	 @LookupValue 	 VarChar(7000) 	 OUTPUT,
 	 @PUId 	  	 Int,
 	 @PropertyName 	 VarChar(255),
 	 @DefaultValue 	 VarChar(7000) = NULL
AS
SELECT 	 @LookupValue = NULL
-------------------------------------------------------------------------------
-- Retrieve the property value for the passed PUId and parameter names
-------------------------------------------------------------------------------
SELECT 	 @LookupValue = TFV.Value
 	 FROM 	 Table_Fields_Values TFV
 	 JOIN 	 Table_Fields TF
 	 ON 	 TF.Table_Field_Id  	 = TFV.Table_Field_id
 	 JOIN 	 Tables T
 	 ON 	 T.TableId 	  	 = TFV.TableId
 	 WHERE 	 TF.Table_Field_Desc  	 = @PropertyName
 	 AND 	 T.TableName 	  	 = 'Prod_Units'
 	 AND 	 TFV.KeyId 	  	 = @PUId
-------------------------------------------------------------------------------
-- If a generic or specific lookup wasn't found, then return the DefaultValue
-- that was passed into this SP.
-------------------------------------------------------------------------------
IF 	 @LookupValue IS NULL
BEGIN
 	 SELECT 	 @LookupValue = @DefaultValue
END
RETURN
