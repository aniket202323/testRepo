-------------------------------------------------------------------------------
-- This Stored Procedure will retrieve a parameter value associated with a model.
-- It may be called several times by event model SPs to return values that would 
-- otherwise have been hard-coded into the SPs.
--
-- Date 	  	 Version 	 Build 	 Author  Comment
-- 14-Jan-2004 	 001 	 001 	 AlexJ 	 Initial coding.
-- 27-Mar-2004 	 001 	 002 	 BrentS 	 Added support for default value from the
-- 	  	  	  	  	 model definition.
--
-------------------------------------------------------------------------------
CREATE  	 PROCEDURE dbo.spCmn_ModelParameterLookup
 	 @LookupValue 	 VARCHAR(1000) 	 OUTPUT,
 	 @ECId 	  	 INT,
 	 @PropertyName 	 VARCHAR(255),
 	 @DefaultValue 	 VARCHAR(1000) = NULL
AS
SELECT 	 @LookupValue = NULL
-------------------------------------------------------------------------------
-- Retrieve the default value from the model definition.
-------------------------------------------------------------------------------
SELECT 	 @LookupValue = edp.Default_Value
 	 FROM 	 Event_Configuration ec
 	 JOIN 	 ED_Field_Properties edp ON ec.ED_Model_Id = edp.ED_Model_Id
 	  	 AND 	 edp.Field_Desc = @PropertyName
 	 WHERE 	 ec.EC_Id = @ECId
-------------------------------------------------------------------------------
-- Retrieve the parameter value for the passed ECId and parameter names
-------------------------------------------------------------------------------
SELECT 	 @LookupValue = ECP.Value
 	 FROM 	 Event_Configuration_Properties ECP
 	 JOIN 	 ED_Field_Properties EFP ON ECP.ED_Field_Prop_Id = EFP.ED_Field_Prop_Id
 	 WHERE 	 ECP.EC_Id = @ECId
 	 AND 	 EFP.Field_Desc = @PropertyName
-------------------------------------------------------------------------------
-- If a generic or specific lookup wasn't found, then return the DefaultValue
-- that was passed into this SP.
-------------------------------------------------------------------------------
IF 	 @LookupValue IS NULL
 	 SELECT 	 @LookupValue = @DefaultValue
RETURN
