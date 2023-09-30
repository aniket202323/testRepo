
--Step B Creation Of Function
CREATE FUNCTION dbo.fnLocal_eCIL_GetProdLinesForCL(@UserId INT, @MinimumAccessLevel INT)
RETURNS @LineId TABLE(PL_Id INT)
/*
SQL Function			:		fnLocal_eCIL_GetProdLinesForCL
Author					:		Payal Gadhvi 
Date Created			:		22-Mar-2023
Function Type			:		Table-Valued
Editor Tab Spacing		:		3
Description:
===========
Returns a Table of Production Line Ids associated with Centerline
CALLED BY				:  SP
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			22-Mar-2023		Payal Gadhvi			Creation

TEST CODE :
SELECT * FROM dbo.fnLocal_eCIL_GetProdLinesForCL (58,2)
*/

AS
BEGIN

--add CL line excluding the one which has eCIL UDP because we will add eCIL lines in another seciton
INSERT  @LineId (PL_Id)
	SELECT DISTINCT PL_Id  from dbo.Prod_Units_Base pu with (nolock)
	JOIN dbo.Event_Configuration ec	WITH (NOLOCK)	ON	pu.Pu_Id =	ec.Pu_Id
	join dbo.Event_Subtypes es with (nolock) ON ec.Event_Subtype_Id = es.Event_Subtype_Id
	where es.Event_Subtype_Desc like 'RTT%' and dbo.fnLocal_eCIL_Is_eCIL_Line(PL_Id) = 0

RETURN 
END
