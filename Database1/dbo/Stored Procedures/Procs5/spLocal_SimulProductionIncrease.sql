

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_SimulProductionIncrease
--------------------------------------------------------------------------------------------------
-- Author				: Simon Poon GE
-- Date created			: 07-Aug-12
-- Version 				: Version <1.0>
-- SP Type				: PA Calculation
-- Caller				: Called by a change of the Production count Change
-- Description			: This Stored Procedure is to calculation the Raw Material consumption and Update
--						  The Genealogy Link
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------

-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ============	===============	=======================	==========================================
-- Version		Date			Modified By				Description
-- ============	===============	=======================	==========================================
-- 1.0			2015-03-06		Ugo Lapierre
--================================================================================================
/*
Declare	@OutputValue	nvarchar(25)
Exec spLocal_SimulProductionIncrease
	@OutputValue				OUTPUT,
	@puid						=
	@TimeStamp					= '2013-07-23 14:25:00',
	@DefaultUserName			= 'System.PE',	
	
SELECT @OutputValue as OutputValue
*/
-------------------------------------------------------------------------------
CREATE  PROCEDURE [dbo].[spLocal_SimulProductionIncrease]
		@OutputValue				varchar(25) OUTPUT,
		@PUId						int,				-- This Variable / Master PUId / False
		@TimeStamp					datetime

AS
SET NOCOUNT ON

DECLARE 
@StartTime					datetime,
@Seconds					FLOAT



SELECT @StartTime = start_time
FROM dbo.events 
WHERE pu_id = @puid
	AND timestamp = @TimeStamp


SELECT @Seconds = DATEDIFF(ss,@StartTime,@TimeStamp)/5

SELECT @OutputValue = CONVERT(int,@Seconds)
	
SET NOCOUNT OFF

