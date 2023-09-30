
-----------------------------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnRptCrewFilter
-----------------------------------------------------------------------------------------------------------------------
-- Author				: Fernando Rio - Arido Software
-- Date created			: 2013-12-17
-- Version 				: 1.3
-- SP Type				: Report Stored Procedure
-- Caller				: Report
-- Description			: This stored procedure will filter the Crew/Shifts according a Workcell list selected
-- Editor tab spacing	: 4 
-- --------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- --------------------------------------------------------------------------------------------------------------------
-- ========	====	  		====					=====
-- 1.0		2013-12-17		Fernando Rio    		Initial Release
-- 1.1		2013-12-17		Fernando Rio			Added an output recordset
-- 1.2		2013-12-17		Fernando Rio			Added Start/End Time as parameters
-- 1.3		2013-12-19		Martin Casalis			Added Value Stream parameter   
-- 1.4		2014-03-07		Martin Casalis			Replaced between condition by comparison operators
--
-- 2.0      2014-03-14		Fernando Rio			Created new refactored version for SOADB	
-- 2.1		2015-06-22		Martin Casalis			Removed value stream input parameter logic. Only use machines ids
-- 2.2		2015-06-26		Martin Casalis			FO-02211: For all DMO project reports remove the database reference from all code\
-- 1.1		2015-11-09		Fran Osorno				new location
-- 1.2		2016-11-02		Martin Casalis			Added execute permissions to comxclient user
-- 1.3		2017-10-03		Martin Casalis			Changed input parameter @strWorkCellId to NVARCHAR(MAX)
-- 1.4		2018-07-24		Martin Casalis			FO-03531: Include the Shifts that ends at the same start time of report
--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_CmnRptCrewFilter]
--DECLARE 
		@strWorkCellId		NVARCHAR(MAX)		,    -- List Of PUIds
		@strFilterFlag		NVARCHAR(10)		,
		@startTime			DATETIME			,
		@endTime			DATETIME			,
		@strValueStream		NVARCHAR(200)		
---- 
---- select * from prod_units where pu_id 
--SET @strWorkCellId		= '1371'  --,'1/1/1960','1/1/1960'
--SET @strFilterFlag		= 'Crew'				 -- 'Shift'
--SET @startTime			= '2015-03-02 06:30:00'			
--SET	@endTime			= '2015-03-03 06:21:00'			
--SET	@strValueStream		= 'Training VS1,Training VS7'
---------------------------------------------------------------------------------------------------
--WITH ENCRYPTION
AS
---------------------------------------------------------------------------------------------------
DECLARE @WorkCellList TABLE	(
		EquipmentId				UNIQUEIDENTIFIER,
		SKEqId					INT				,
		WCId					INT				,
		PUId					INT				,
		PUDesc					NVARCHAR(200)	)
---------------------------------------------------------------------------------------------------
DECLARE @OutputTable TABLE	(
		ShiftDesc				NVARCHAR(200))
---------------------------------------------------------------------------------------------------		
DECLARE @tblValueStream TABLE (
		VSId						INT IDENTITY	,
		ValueStream					NVARCHAR(200) )
---------------------------------------------------------------------------------------------------		
DECLARE @tblVSMachine TABLE (
		VSMachineId					INT				,
		VSMachineDesc				NVARCHAR(200) )
---------------------------------------------------------------------------------------------------
DECLARE @TempTable TABLE(
		TempDesc					NVARCHAR(255)	)
---------------------------------------------------------------------------------------------------
DECLARE
		@index			INT					,
		@strDesc		NVARCHAR(400)		,
		@strDescTemp	NVARCHAR(400)		
--
--
IF @startTime = '1/1/1960'	SET @startTime	= DATEADD(dd,-30,GETDATE())
IF @endTime = '1/1/1960'	SET @endTime	= GETDATE()
---------------------------------------------------------------------------------------------------
-- Step 1. Gather the Production Units
---------------------------------------------------------------------------------------------------
IF @strWorkCellId > ''
BEGIN	
	INSERT INTO @WorkCellList (PUId, PUDesc)
	EXECUTE ('SELECT PU_Id, PU_Desc FROM dbo.Prod_Units_Base WITH(NOLOCK) WHERE PU_Id IN (' + @strWorkCellId + ')')
END


--SELECT * FROM @tblValueStream
--select '@WorkCellList',* from @WorkCellList
---------------------------------------------------------------------------------------------------
-- Step 2. Filter Crew Schedule
---------------------------------------------------------------------------------------------------
IF @strFilterFlag = 'Crew'
BEGIN
		INSERT INTO @OutputTable(ShiftDesc)
		SELECT	DISTINCT Crew_Desc
		FROM	dbo.Crew_Schedule		cs	WITH(NOLOCK)
		JOIN    @WorkCellList			wc	ON cs.PU_Id = wc.PUId
		WHERE   Start_Time < @endTime  
			AND End_Time >= @startTime
END
ELSE 
BEGIN
		INSERT INTO @OutputTable(ShiftDesc)
		SELECT	DISTINCT Shift_Desc
		FROM	dbo.Crew_Schedule		cs	WITH(NOLOCK)
		JOIN    @WorkCellList			wc	ON cs.PU_Id = wc.PUId 
		WHERE   Start_Time < @endTime  
			AND End_Time >= @startTime
END

SELECT ShiftDesc FROM @OutputTable 

SET NOCOUNT OFF
