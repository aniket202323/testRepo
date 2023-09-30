--------------------------------------------------------------------------------------------------------
-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_RTT_IsValidLineStatus] (@LineStatus varchar(25))
/*
----------------------------------------------
SQL Function:			fnLocal_RTT_IsValidLineStatus
Author:					Alexandre Turgeon (System Technologies for Industry Inc)
Date Created:			22-Jun-2009
Function Type:			Scalar
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
===========
Check if the Line Status received as parameter is valid for eCIL application
Looks at the RTT_STLS_IsValidLineStatus UDP on the corresponding phrase of the Line Status Data Type

Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.0.0				22-Jun-2009		Alexandre Turgeon			Creation
1.1					29-Jan-2108		Fernando Rio				Modified to work with NPT
--------------------------------------------------------------------------------------------------------
TEST CODE :
SELECT dbo.fnLocal_RTT_IsValidLineStatus('PR In:Line Normal')
SELECT dbo.fnLocal_RTT_IsValidLineStatus('PR Out:Line Not Staffed')
--------------------------------------------------------------------------------------------------------
*/

RETURNS bit
--DECLARE @LineStatus varchar(25)

--SET @LineStatus = 'PR In:Line Normal'
--SET @LineStatus = 'PR In:E.O. Shippable'
AS
BEGIN
	DECLARE
	@IsValidLineStatus	bit

	-- If the Site uses the OLd STLS method then look into phrases:
	IF EXISTS ( SELECT *
						FROM		dbo.Phrase p						WITH (NOLOCK)
						JOIN		dbo.Data_Type dt					WITH (NOLOCK)	ON		p.Data_Type_Id = dt.Data_Type_Id
						WHERE		p.Phrase_Value = @LineStatus
						AND		dt.Data_Type_Desc = 'Line Status')
	BEGIN
		SET @IsValidLineStatus =
							( 
							SELECT	tfv.Value
							FROM		dbo.Phrase p						WITH (NOLOCK)
							JOIN		dbo.Data_Type dt					WITH (NOLOCK)	ON		p.Data_Type_Id = dt.Data_Type_Id
							JOIN		dbo.Table_Fields_Values tfv	WITH (NOLOCK)	ON		p.Phrase_Id = tfv.KeyId
							JOIN		dbo.Table_Fields tf				WITH (NOLOCK)	ON		tfv.Table_Field_Id = tf.Table_Field_Id
							WHERE		p.Phrase_Value = @LineStatus
							AND		dt.Data_Type_Desc = 'Line Status'
							AND		tf.Table_Field_Desc = 'RTT_STLS_IsValidLineStatus'
							)
	END
	ELSE
	BEGIN
		SET @IsValidLineStatus = (
						SELECT 	tfv.Value
						FROM   dbo.Event_Reason_Tree ert			WITH(NOLOCK)
						JOIN   dbo.Event_Reason_Tree_Data ertd		WITH(NOLOCK)	ON		ert.Tree_Name_id = ertd.Tree_Name_Id
						JOIN   dbo.Event_Reasons er					WITH(NOLOCK)	ON		er.Event_Reason_Id = ertd.Event_Reason_Id
						JOIN   dbo.Table_Fields_Values tfv			WITH (NOLOCK)	ON		er.Event_Reason_Id = tfv.KeyId
						JOIN   dbo.Table_Fields tf					WITH (NOLOCK)	ON		tfv.Table_Field_Id = tf.Table_Field_Id
						WHERE  Tree_Name = 'Non-Productive Time'
						AND		tf.Table_Field_Desc = 'RTT_STLS_IsValidLineStatus')
	END

	RETURN isnull(@IsValidLineStatus, 0)
END



