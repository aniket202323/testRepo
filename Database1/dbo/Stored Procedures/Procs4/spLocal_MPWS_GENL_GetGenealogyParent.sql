 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetGenealogyParent]
		@EventId			INT,
		@ParentPUDescMask	varchar(50) = '%'
		
AS	
-------------------------------------------------------------------------------
-- Get Parent(s) through Genealogy for the passed event_Id
--Mask can be used to limit parents allows using LIKE on Parent PU_Desc
/*
spLocal_MPWS_GENL_GetGenealogyParent 5739157, '%Kitting%'
*/
-- Date         Version Build Author  
-- 06-JUN-2016  001     001   Chris Donnelly (GE Digital)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
DECLARE	@tPO1				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	Parent_Event_Id			INT									NULL,
	[TimeStamp]				DATETIME
)
-------------------------------------------------------------------------------
--  Get Parents
-------------------------------------------------------------------------------
INSERT	@tPO1 (Parent_Event_Id,[TimeStamp])
	SELECT ec.Source_Event_Id, ec.TimeStamp
		FROM dbo.Event_Components ec
			JOIN dbo.[Events] pe on pe.Event_Id = ec.Source_Event_Id
			JOIN dbo.Prod_Units_Base p on p.PU_Id = pe.PU_Id
		WHERE 
			ec.Event_Id = @EventId
			AND 
			p.PU_Desc LIKE @ParentPUDescMask
		ORDER BY 
			ec.[TimeStamp] DESC
		
 
IF		@@ROWCOUNT	= 0
	BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'No Genealogy Parent found for this Event')
	END
ELSE
	BEGIN
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (1, 'Success')
	END
 
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
 
--Return Status
--Return Status
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
--Return Data
SELECT 
		Id						Id,
		Parent_Event_Id			Parent_Event_Id,
		[TimeStamp]				TimeStamp
	FROM @tPO1
		
 
 
 
 
