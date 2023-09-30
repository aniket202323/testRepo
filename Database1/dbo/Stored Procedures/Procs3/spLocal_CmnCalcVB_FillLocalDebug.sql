
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre
-- Date created			: 20-Apr-2020
-- Version 				: 1.00
-- SP Type				: Calculation
-- Caller				: 
-- Description			: FIll local debug for testing
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		20-Apr-2020		Ugo Lapierre					Created Stored Procedure

--================================================================================================
/*
DECLARE @OutputValue varchar(25)
EXEC spLocal_CmnCalcVB_FillLocalDebug @OutputValue OUTPUT
SELECT @OutputValue
*/


CREATE PROCEDURE [dbo].[spLocal_CmnCalcVB_FillLocalDebug]
		@OutputValue				varchar(25) OUTPUT,
		@Num						int



AS
SET NOCOUNT ON
DECLARE @Temps	datetime,
		@i		int

SET @Temps = GETDATE()
SET @i = 0

WHILE @i<@Num
BEGIN
	INSERT LOCAL_DEBUG (timestamp, callingSP, message, msg)
	VALUES (getdate(),'spLocal_CmnCalcVB_FillLocalDebug', 'loop #' + CONVERT(varchar(5),@i), @i)

	--WAITFOR DELAY '00:00:00.005'

	SET @i = @i+1
END



SELECT	@OutputValue = CONVERT(varchar(30),@Temps,120)

RETURN



