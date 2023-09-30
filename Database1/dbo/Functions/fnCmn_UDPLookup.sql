
-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnCmn_UDPLookup]	(
														@TableId  		int,
 														@KeyId 	  		int,
 														@PropertyName  varchar(255),
 														@DefaultValue  varchar(1000) = NULL)
 														
/*
SQL Function			:		fnCmn_UDPLookup
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		07-Sep-2006
Function Type			:		Scalar
Editor Tab Spacing	:		3

Description:
===========
Retrieves a parameter value from a table that is passed to the function as the TableId.

CALLED BY				:  SP


Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.0.0				07-Sep-2006		Normand Carbonneau		Creation

1.0.1				17-Jun-2008		Normand Carbonneau		Fixed Default Value logic. Default Value was ignored.


TEST CODE :
SELECT dbo.fnCmn_UDPLookup (20, 457, 'Variable_Type', NULL)

*/

RETURNS varchar(1000)

AS
BEGIN

DECLARE @LookupValue varchar(1000)


-------------------------------------------------------------------------------
-- Retrieve the parameter value for the passed TableId, KeyId and Parameter Name
-------------------------------------------------------------------------------
SET @LookupValue =	(
							SELECT	tfv.Value
  							FROM  	dbo.Table_Fields_Values tfv
 							JOIN		dbo.Table_Fields tf ON tf.Table_Field_Id = tfv.Table_Field_Id
 							JOIN		dbo.Tables t ON t.TableID = tfv.TableID
 	  						WHERE		t.TableId = @TableId 
 	  	  					AND		tf.Table_Field_Desc = @PropertyName
 	  	  	  				AND		tfv.KeyId = @KeyID
 	  	  	  				)

	RETURN isnull(@LookupValue, @DefaultValue)
END

