--------------------------------------------------------------------------------------------------
-- Local Function: [fnLocal_CmnRptDefectsReport]
--------------------------------------------------------------------------------------------------
-- Author				: Arido Software
-- Date created			: 2012-09-13
-- Version 				: 1.4
-- Description			: This local function returns a table of defect records based on parameters
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====				=====
-- 1.0			2012-09-13		Arido Software    	Initial Release
-- 1.1			2012-11-29		Mike Thomas			Matched @tblDefects field sizes with esop Defects table
-- 1.2			2013-08-22		Mike Thomas			Added Task Name and Task Step Name
-- 1.3			2013-11-06		Mike Thomas			Updated for SOA 2.1 (New defects Table)
-- 2.0			2014-03-11		Marc Côté (Factora)	Refactoring for SOADB
-- 2.1			2014-04-07		Mike Thomas			Added 4th-7th level FL in results. Get FL number from defects table.
-- 2.2			2014-04-23		Mike Thomas			Increased size of the input parameters for equipment.
-- 2.3			2014-05-07		Martin Casalis		Remove the domain from FixedBy and FoundBy fields
-- ===================================================================================================================
CREATE FUNCTION [dbo].[fnLocal_CmnRptDefectsReport] (
--DECLARE
			@intAreaId				NVARCHAR(100)	,	-- S95 Area
			@intProdLineId			NVARCHAR(800)	,	-- S95 Work Center
			@intWorkCellId			NVARCHAR(MAX)	,	-- S95 Work Unit
			@dtmStartTime			DATETIME		,
			@dtmEndTime				DATETIME		
	)
	RETURNS @tblDefects TABLE (
	--DECLARE @tblDefects TABLE (
			DefectNumber			INT,
			LineDesc				NVARCHAR(255),
			Equipment				NVARCHAR(255),
			Category				NVARCHAR(255),
			TaskName				NVARCHAR(200),
			TaskStepName			NVARCHAR(200),
			FLName					NVARCHAR(255),
			DateCreation			DATETIME	 ,	
			ShortDesc				NVARCHAR(500),
			DetDesc					NVARCHAR(3000),
			Status					NVARCHAR(25) ,
			FoundBy					NVARCHAR(200),
			TargetCorrectionDate	DATETIME,
			CorrectedDate			DATETIME,
			CorrectedComments		NVARCHAR(3000),
			FixedByName				NVARCHAR(200),
			ExternalHelpNeeded		NVARCHAR(10)
	)
AS 

--===============================================================================================================================
--	Testing
--	SELECT * FROM SOADB.dbo.fnLocal_CmnRptDefectsReport ('4', '52', '432,433', '2013-12-16', '2014-01-23' )
---------------------------------------------------------------------------------------------------------------------------------

BEGIN

	--SELECT  
	--		@intAreaId			= '4',			--Dept_ID
	--		@intProdLineId		= '52',			--PL_Id
	--		@intWorkCellId		= '350,348',	--PU_Id
	--		@dtmStartTime		= '2013-12-16' ,
	--		@dtmEndTime			= '2014-01-23' 
	--===============================================================================================================================
	-- Variable Declaration
	---------------------------------------------------------------------------------------------------------------------------------
	DECLARE	@i				int,
			@stringToSplit	varchar(MAX),
			@intId			int

	--===============================================================================================================================
	-- Table Variable Declaration
	---------------------------------------------------------------------------------------------------------------------------------
	DECLARE @Equipment TABLE (
		EquipmentId	uniqueidentifier,					
		Equipment	nvarchar(100),
		WCType		nvarchar(255))

	DECLARE @tblDeptIds TABLE (
		RcdId		int identity, 
		DeptId		int )

	DECLARE @tblPLIds TABLE (
		RcdId		int identity, 
		PLId		int )
			
	DECLARE @tblPUIds TABLE (
		RcdId		int identity, 
		PUId		int )

	---------------------------------------------------------------------------------------------------
	-- Get Department Ids in table
	---------------------------------------------------------------------------------------------------
	IF (LEN(@intAreaId) > 0)
	BEGIN
		-- Split the input on Ids array
		SET @i = 1
		SET @stringToSplit = @intAreaId
		WHILE @i > 0
		BEGIN

			  SET @i = CHARINDEX(',',@stringToSplit)

			  IF (@i = 0 AND LEN(@stringToSplit) > 0)
			  BEGIN
					INSERT INTO @tblDeptIds (DeptId)
					SELECT @stringToSplit
			  END
			  ELSE
			  BEGIN
					SET @intId = SUBSTRING(@stringToSplit, 1, @i - 1)
					INSERT INTO @tblDeptIds (DeptId)
					SELECT @intId
			  END

			  SET @stringToSplit = SUBSTRING(@stringToSplit, @i + 1, LEN(@stringToSplit))
		END
	END

	---------------------------------------------------------------------------------------------------
	-- Get Production Line Ids in table
	---------------------------------------------------------------------------------------------------
	IF (LEN(@intProdLineId) > 0)
	BEGIN
		-- Split the input on Ids array
		SET @i = 1
		SET @stringToSplit = @intProdLineId
		WHILE @i > 0
		BEGIN

			  SET @i = CHARINDEX(',',@stringToSplit)

			  IF (@i = 0 AND LEN(@stringToSplit) > 0)
			  BEGIN
					INSERT INTO @tblPLIds (PLId)
					SELECT @stringToSplit
			  END
			  ELSE
			  BEGIN
					SET @intId = SUBSTRING(@stringToSplit, 1, @i - 1)
					INSERT INTO @tblPLIds (PLId)
					SELECT @intId
			  END

			  SET @stringToSplit = SUBSTRING(@stringToSplit, @i + 1, LEN(@stringToSplit))
		END
	END

	---------------------------------------------------------------------------------------------------
	-- Get Production Unit Ids in table
	---------------------------------------------------------------------------------------------------
	IF (LEN(@intWorkcellId) > 0)
	BEGIN
		-- Split the input on Ids array
		SET @i = 1
		SET @stringToSplit = @intWorkcellId
		WHILE @i > 0
		BEGIN

			  SET @i = CHARINDEX(',',@stringToSplit)

			  IF (@i = 0 AND LEN(@stringToSplit) > 0)
			  BEGIN
					INSERT INTO @tblPUIds (PUId)
					SELECT @stringToSplit
			  END
			  ELSE
			  BEGIN
					SET @intId = SUBSTRING(@stringToSplit, 1, @i - 1)
					INSERT INTO @tblPUIds (PUId)
					SELECT @intId
			  END

			  SET @stringToSplit = SUBSTRING(@stringToSplit, @i + 1, LEN(@stringToSplit))
		END
	END

	---------------------------------------------------------------------------------------------------
	-- Get the Equipment INformation to build the FL
	---------------------------------------------------------------------------------------------------	
	-- Get the selected Areas	
	INSERT INTO		@Equipment(EquipmentID, Equipment)
		SELECT		e.EquipmentId, e.S95Id
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		SOADB.dbo.PAEquipment_Aspect_SOAEquipment	pa		WITH(NOLOCK)	ON  pa.Origin1EquipmentId = e.EquipmentId
		JOIN		@tblDeptIds									v						ON	v.DeptId = pa.Dept_Id 

	-- Get the Selected lines 
	INSERT INTO		@Equipment(EquipmentID, Equipment)
		SELECT		e.EquipmentId, e.S95Id
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		SOADB.dbo.PAEquipment_Aspect_SOAEquipment	pa		WITH(NOLOCK)	ON  pa.Origin1EquipmentId = e.EquipmentId
		JOIN		@tblPLIds									v						ON	v.PLId = pa.PL_Id 

	-- Get the selected Work Cells
	INSERT INTO		@Equipment(EquipmentID, Equipment, WCType)
		SELECT		e.EquipmentId, e.S95Id, 'FL3' 
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		SOADB.dbo.PAEquipment_Aspect_SOAEquipment	pa		WITH(NOLOCK)	ON  pa.Origin1EquipmentId = e.EquipmentId
		JOIN		@tblPUIds									v						ON	v.PUId = pa.PU_Id 

	-- Get 4th Level Work Cells
	INSERT INTO		@Equipment(EquipmentID, Equipment, WCType)
		SELECT		e.EquipmentId, e.S95Id, 'FL4' 
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		@Equipment									e2						ON e2.EquipmentId = e.ParentEquipmentId
		WHERE e2.WCType = 'FL3'
	
	-- Get 5th Level Work Cells
	INSERT INTO		@Equipment(EquipmentID, Equipment, WCType)
		SELECT		e.EquipmentId, e.S95Id, 'FL5' 
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		@Equipment									e2						ON e2.EquipmentId = e.ParentEquipmentId
		WHERE e2.WCType = 'FL4'
		
	-- Get 6th Level Work Cells
	INSERT INTO		@Equipment(EquipmentID, Equipment, WCType)
		SELECT		e.EquipmentId, e.S95Id, 'FL6' 
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		@Equipment									e2						ON e2.EquipmentId = e.ParentEquipmentId
		WHERE e2.WCType = 'FL5'
		
	-- Get 7th Level Work Cells
	INSERT INTO		@Equipment(EquipmentID, Equipment, WCType)
		SELECT		e.EquipmentId, e.S95Id, 'FL7' 
		FROM		SOADB.dbo.Equipment							e		WITH(NOLOCK)
		JOIN		@Equipment									e2						ON e2.EquipmentId = e.ParentEquipmentId
		WHERE e2.WCType = 'FL6'
		
	---------------------------------------------------------------------------------------------------
	-- Get Defects
	---------------------------------------------------------------------------------------------------	
	INSERT INTO @tblDefects (
				DefectNumber			,
				LineDesc				,
				Equipment				,
				Category				,
				TaskName				,
				TaskStepName			,
				FLName					,
				DateCreation			,	
				ShortDesc				,
				DetDesc					,
				Status					,
				FoundBy					,
				TargetCorrectionDate	,
				CorrectedDate			,
				CorrectedComments		,
				FixedByName				,
				ExternalHelpNeeded		)	
	SELECT		DefectNumber			,
				e.Equipment				, 
				EquipmentName			, 
				Category				,
				TaskInstanceName		,
				TaskStepInstanceName	, 
				FLNumber				, 
				Created					, 
				ShortDescription		, 
				DetailedDescription		, 
				Status					, 
				SUBSTRING(FoundByName,CHARINDEX('\',FoundByName) + 1,LEN(FoundByName)),
				TargetCorrectionDate	, 
				CorrectedDate			, 
				CorrectedComments		, 
				SUBSTRING(FixedByName,CHARINDEX('\',FixedByName) + 1,LEN(FixedByName)), 
				ExternalHelpNeeded 
	FROM	SOADB.dbo.eSOP_MOTTaskDefects	d	WITH(NOLOCK) 
	JOIN	@Equipment e  
			ON e.EquipmentId = SUBSTRING(d.EquipmentId,CHARINDEX('CN=',d.EquipmentId)+3,CHARINDEX(',CN=',d.EquipmentId)-4) 
	WHERE	CHARINDEX('CN',d.EquipmentId) > 0 
	AND		((d.Created BETWEEN @dtmStartTime AND @dtmEndTime) 
				OR (d.TargetCorrectionDate BETWEEN @dtmStartTime AND @dtmEndTime)
				OR (d.CorrectedDate BETWEEN @dtmStartTime AND @dtmEndTime))

	RETURN
END
