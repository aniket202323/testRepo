


CREATE PROCEDURE [dbo].[spLocal_PCMT_GetSPCTypes]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetSPCTypes
Author:					Marc Charest (STI)	
Date Created:			2007-05-03
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP returns the calculation types

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================
1.1.0		2008-04-22	PD Dubois (STI)		Modified the final result set to be able to add and edit child variables without SPC calculation.
-------------------------------------------------------------------------------------------------
Updated By	:	Patrick-Daniel Dubois (System Technologies for Industry Inc)
Date			:	2008-04-22
Version		:	1.1.0  => Compatible with PCMT version 1.7 and higher
Purpose		: 	Modified the final result set
					This has been done to be able to add and edit child variables without SPC calculation.
					1- I added the variable table @SPC_Table
					2- Insert into it the 'No SPC Calc' calculation description.
-------------------------------------------------------------------------------------------------

*****************************************************************************************************************
*/

AS

SET NOCOUNT ON

DECLARE @SPC_Table TABLE(
[cboSPC] INT,
SPC_Calculation_Type_Desc VARCHAR(50)
)

INSERT INTO @SPC_Table ([cboSPC] ,SPC_Calculation_Type_Desc)
VALUES (-1,'No SPC Calc')
INSERT INTO @SPC_Table ([cboSPC] ,SPC_Calculation_Type_Desc)
SELECT SPC_Calculation_Type_Id AS [cboSPC], SPC_Calculation_Type_Desc 
FROM dbo.SPC_Calculation_Types ORDER BY SPC_Calculation_Type_Desc ASC

SELECT [cboSPC],
		 SPC_Calculation_Type_Desc
FROM @SPC_Table


SET NOCOUNT OFF



