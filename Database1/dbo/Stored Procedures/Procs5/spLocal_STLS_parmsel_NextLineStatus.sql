/*
--------------------------------------------------------------------------------------------------------------------------------------
Name:		spLocal_STLS_parmsel_NextLineStatus
Purpose:	Returns the line status that follows the one passed as an input
Date:		2019/05/27
--------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE PROCEDURE [dbo].[spLocal_STLS_parmsel_NextLineStatus]
	@LineStatusStartTime	DATETIME,
	@UnitDesc				VARCHAR(50)
AS
--------------------------------------------------------------------------------------------------------------------------------------
-- Declare variables
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE
@PR_OUT_PHRASE    VARCHAR(20) = 'pr out:'
--------------------------------------------------------------------------------------------------------------------------------------
-- Check the unit supplied
--------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS	(
					SELECT	1
					FROM	dbo.Prod_Units_Base	WITH(NOLOCK)
					WHERE	PU_Desc = @UnitDesc 
				)
BEGIN
	RETURN	1	-- Line status does not exist or was deleted
END
--------------------------------------------------------------------------------------------------------------------------------------
-- Return next PO
--------------------------------------------------------------------------------------------------------------------------------------
SELECT	TOP 1
		lsn.Status_Schedule_Id									[StatusSchesuleId],
		lsn.Start_DateTime										[StartTime],
		lsn.End_DateTime										[EndTime],
		lsn.Line_Status_Id										[LineStatusId],
		p.Phrase_Value											[LineStatusDesc],
		CASE
			WHEN CHARINDEX(@PR_OUT_PHRASE, p.Phrase_Value) > 0
				THEN	1
			ELSE
				0
		END														[IsPrOut]
FROM	dbo.Prod_Units_Base			pu	WITH(NOLOCK)
JOIN	dbo.Local_PG_Line_Status	lsn					ON	lsn.Unit_Id					=	pu.Pu_Id
														AND	UPPER(lsn.Update_Status)	!=	'DELETE'
JOIN	dbo.Phrase					p	WITH(NOLOCK)	ON	lsn.Line_Status_Id			=	p.Phrase_Id
WHERE	pu.Pu_Desc			= @UnitDesc
AND		lsn.Start_DateTime	> @LineStatusStartTime
ORDER
BY		lsn.Start_DateTime	ASC
--------------------------------------------------------------------------------------------------------------------------------------
--	Footer
--------------------------------------------------------------------------------------------------------------------------------------
