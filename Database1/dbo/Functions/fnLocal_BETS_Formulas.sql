
--=====================================================================================================================
-- Store Procedure: 	fnLocal_BETS_Formulas
-- Author:				Paula Lafuente
-- Date Created:		2008-06-25
-- Sp Type:				Function
-- Editor Tab Spacing: 	4	
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION: 
-- This function returns a result set with the formulas used to calculate the BETS KPI's. 
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-----------------------------------------------------------------------------------------------------------------------
-- spLocal_Rpt_BETSSummary
-- spLocal_Rpt_BETSDDS
-- And any other application that requires BETS formulas
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2008-06-25	Paula Lafuente		Initial Development. 
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-----------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM fnLocal_BETS_Formulas (0)
--=====================================================================================================================
CREATE FUNCTION [dbo].[fnLocal_BETS_Formulas] (
@intLanguageId	INT)

RETURNS 
--DECLARE -- For debug
@tblBETSFormulas	TABLE (
RcdIdx					INT IDENTITY(1,1),
FormulaMeasurePrompt	INT				,
FormulaMeasure			VARCHAR(150)	,
EngUnitsPrompt			INT				,
EngUnitsDesc			VARCHAR(100)	,
FormulaInfo				VARCHAR(1000)	,
Comments				VARCHAR(1000)	,
MaxLength				INT				,
ErrorCode				INT				,
ErrorMsg				VARCHAR(1000)	)	
-----------------------------------------------------------------------------------------------------------------------
AS 
BEGIN
	--=================================================================================================================
	--	DECLARE Variables
	--=================================================================================================================
	--	INT
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@i							INT,
			@intErrorCode				INT,	
			@intMaxStringLength			INT,
			@intFormulaMeasurePrompt	INT,	
			@intFormulaEngUnitsPrompt	INT
	-------------------------------------------------------------------------------------------------------------------
	--	VARCHAR
	-------------------------------------------------------------------------------------------------------------------
	DECLARE	@vchErrorMsg				VARCHAR(1000)	,
			@vchFormulaMeasure			VARCHAR(1000)	,
			@vchFormulaMeasureDefault	VARCHAR(1000)	,
			@vchFormulaEngUnits			VARCHAR(50)		,
			@vchFormulaEngUnitsDefault	VARCHAR(50)		,
			@vchFormula					VARCHAR(1000)	,
			@vchComments				VARCHAR(1000)	
	--=================================================================================================================
	--	FILL table with formulas
	--	a.	Get the prompt number (Note: prompts used are the prompt number for the BETS Summary report and a few from DDS)
	--	b.	Get the prompt string from the dbo.Language_Data table
	--	c.	Get the prompt number for the Eng Units
	--	d.	Get the prompt string for the Eng Units
	--	e.	Get the Multi-Line Roll up formula
	--	f.	Get the Line formula
	--	g.	Get the Constraint1 formula
	--	h.	Get the ConstraintX formula
	--	i.	Get the Machine formula 	
	--================================================================================================================
	--	INITIALIZE variables
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@i = 1
	-------------------------------------------------------------------------------------------------------------------
	--	LOOP to get the values
	-------------------------------------------------------------------------------------------------------------------
	WHILE @i <= 39
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	INITIALIZE variables
		---------------------------------------------------------------------------------------------------------------
		SELECT	@intMaxStringLength 		= 0,
				@intFormulaMeasurePrompt	= 0,
				@vchFormulaMeasure			= '',
				@vchFormulaMeasureDefault 	= '',
				@vchFormulaEngUnits			= '',
				@vchFormulaEngUnitsDefault 	= '',
				@vchFormula					= '',
				@vchComments				= ''
		---------------------------------------------------------------------------------------------------------------
		--	a.	Get the prompt number (Note: prompts used are the prompt number for the BETS Summary report and a few from DDS)
		---------------------------------------------------------------------------------------------------------------
		SELECT @intFormulaMeasurePrompt = 	CASE	WHEN @i = 1  	THEN	99830014	
													WHEN @i = 2  	THEN	99830015
													WHEN @i = 3  	THEN	99830016
													WHEN @i = 4  	THEN	99830065
													WHEN @i = 5  	THEN	99830018
													WHEN @i = 6  	THEN	99830019
													WHEN @i = 7  	THEN	99830020
													WHEN @i = 8  	THEN	99830022
													WHEN @i = 9  	THEN	99830023
													WHEN @i = 10  	THEN	99830027
													WHEN @i = 11  	THEN	99830024
													WHEN @i = 12  	THEN	99830025
													WHEN @i = 13  	THEN	99830026
													WHEN @i = 14  	THEN	99830017
													WHEN @i = 15  	THEN	99830039
													WHEN @i = 16  	THEN	99830040
													WHEN @i = 17  	THEN	99830041
													WHEN @i = 18  	THEN	99830042
													WHEN @i = 19  	THEN	99830043
													WHEN @i = 20  	THEN	99830044
													WHEN @i = 21  	THEN	99830045
													WHEN @i = 22  	THEN	99830046
													WHEN @i = 23  	THEN	99830047
													WHEN @i = 24  	THEN	99830048
													WHEN @i = 25  	THEN	99830049
													WHEN @i = 26  	THEN	99830050
													WHEN @i = 27  	THEN	99830051
													WHEN @i = 28  	THEN	NULL
													WHEN @i = 29  	THEN	99830066
													WHEN @i = 30  	THEN	99831018
													WHEN @i = 31  	THEN	99831019
													WHEN @i = 32  	THEN	99831020
													WHEN @i = 33  	THEN	99831021
													WHEN @i = 34  	THEN	99831026
													WHEN @i = 35  	THEN	99831040
													WHEN @i = 36  	THEN	99831041
													WHEN @i = 37  	THEN	99831042
													WHEN @i = 38  	THEN	99831057
													WHEN @i = 39  	THEN	99831058
													END
		---------------------------------------------------------------------------------------------------------------
		--	b.	Get the prompt string from the dbo.Language_Data table
		---------------------------------------------------------------------------------------------------------------
		SELECT 	@vchFormulaMeasure = Prompt_String
		FROM	dbo.Language_Data	WITH (NOLOCK) 	
		WHERE	Prompt_Number = COALESCE(@intFormulaMeasurePrompt,0)
			AND	Language_Id = @intLanguageId
		---------------------------------------------------------------------------------------------------------------
		--		Get a default value in case prompt does not exists
		---------------------------------------------------------------------------------------------------------------
		SELECT @vchFormulaMeasureDefault = 	CASE	WHEN @i = 1	 THEN	'Total Report Time'
													WHEN @i = 2	 THEN	'Total Schedule Time'
													WHEN @i = 3	 THEN	'Total Uptime'
													WHEN @i = 4  THEN	'Total STNU'
													WHEN @i = 5	 THEN	'Total Unplanned Losses'
													WHEN @i = 6	 THEN	'Total Planned Losses'
													WHEN @i = 7	 THEN	'Total Losses'
													WHEN @i = 8	 THEN	'PR Loss (%)'
													WHEN @i = 9	 THEN	'Making System PR'
													WHEN @i = 10 THEN	'Making System RE'
													WHEN @i = 11 THEN	'Making System RU'
													WHEN @i = 12 THEN	'Making System SU'
													WHEN @i = 13 THEN	'Making System CU'
													WHEN @i = 14 THEN	'Total MSU'
													WHEN @i = 15 THEN	'# of Batches'
													WHEN @i = 16 THEN	'Formula Efficiency'
													WHEN @i = 17 THEN	'Formula Yield'
													WHEN @i = 18 THEN	'Total Loss Events'
													WHEN @i = 19 THEN	'Total Loss Event Times'
													WHEN @i = 20 THEN	'Operational Loss Time'
													WHEN @i = 21 THEN	'Minor Stops Loss Time'
													WHEN @i = 22 THEN	'Process Failure Loss Time'
													WHEN @i = 23 THEN	'Breakdown Loss Time'
													WHEN @i = 24 THEN	'Quality Loss Time'
													WHEN @i = 25 THEN	'Starved Loss Time'
													WHEN @i = 26 THEN	'Supply Loss Time'
													WHEN @i = 27 THEN	'Deadband Loss Time'
													WHEN @i = 28 THEN	'Dynamic Sections Time'
													WHEN @i = 29 THEN	'EO Loss Time'
													WHEN @i = 30 THEN	'Volume'
													WHEN @i = 31 THEN	'Target Time'
													WHEN @i = 32 THEN	'Actual BCT'
													WHEN @i = 33 THEN	'Avg Difference'
													WHEN @i = 34 THEN	'Total Report Time'
													WHEN @i = 35 THEN	'Stops'
													WHEN @i = 36 THEN	'DownTime'
													WHEN @i = 37 THEN	'Loss'
													WHEN @i = 38 THEN	'Stop Clasification'
													WHEN @i = 39 THEN	'Loss Time'
													END
		---------------------------------------------------------------------------------------------------------------
		--	Replace by default is prompt string is not found
		---------------------------------------------------------------------------------------------------------------
		IF	LEN(@vchFormulaMeasure) = 0
		BEGIN
			SELECT	@vchFormulaMeasure = @vchFormulaMeasureDefault
		END
		---------------------------------------------------------------------------------------------------------------
		--	c.	Get the prompt number for the Eng Units
		---------------------------------------------------------------------------------------------------------------
		SELECT @intFormulaEngUnitsPrompt	= 	CASE	WHEN @i = 1  	THEN	99830062
														WHEN @i = 2  	THEN	99830062
														WHEN @i = 3  	THEN	99830062
														WHEN @i = 4  	THEN	99830062
														WHEN @i = 5  	THEN	99830062
														WHEN @i = 6  	THEN	99830062
														WHEN @i = 7  	THEN	99830062
														WHEN @i = 8  	THEN	99830060
														WHEN @i = 9  	THEN	99830060
														WHEN @i = 10  	THEN	99830060
														WHEN @i = 11  	THEN	99830060
														WHEN @i = 12  	THEN	99830060
														WHEN @i = 13  	THEN	99830060
														WHEN @i = 14  	THEN	99830060
														WHEN @i = 15  	THEN	99830061
														WHEN @i = 16  	THEN	99830060
														WHEN @i = 17  	THEN	99830060
														WHEN @i = 18  	THEN	99830061
														WHEN @i = 19  	THEN	99830062
														WHEN @i = 20  	THEN	99830062
														WHEN @i = 21  	THEN	99830062
														WHEN @i = 22  	THEN	99830062
														WHEN @i = 23  	THEN	99830062
														WHEN @i = 24 	THEN	99830062
														WHEN @i = 25  	THEN	99830062
														WHEN @i = 26  	THEN	99830062
														WHEN @i = 27  	THEN	99830062
														WHEN @i = 28  	THEN	99830062
														WHEN @i = 29 	THEN	99830062
														WHEN @i = 30  	THEN	NULL
														WHEN @i = 31  	THEN	99830062
														WHEN @i = 32  	THEN	99830062
														WHEN @i = 33  	THEN	99830062
														WHEN @i = 34  	THEN	99830062
														WHEN @i = 35  	THEN	99830061
														WHEN @i = 36  	THEN	99831050
														WHEN @i = 37  	THEN	99830060
														WHEN @i = 38  	THEN	99830061
														WHEN @i = 39  	THEN	99830062
														END
		---------------------------------------------------------------------------------------------------------------
		--	d.	Get the prompt string for the Eng Units
		---------------------------------------------------------------------------------------------------------------
		SELECT 	@vchFormulaEngUnits = Prompt_String
		FROM	dbo.Language_Data	WITH (NOLOCK) 	
		WHERE	Prompt_Number = COALESCE(@intFormulaEngUnitsPrompt,0)
			AND	Language_Id = @intLanguageId
		---------------------------------------------------------------------------------------------------------------
		--		Get a default value is prompt string is not founc
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchFormulaEngUnitsDefault	=	CASE	WHEN @i = 1  	THEN	'min'
														WHEN @i = 2  	THEN	'min'
														WHEN @i = 3  	THEN	'min'
														WHEN @i = 4  	THEN	'min'
														WHEN @i = 5  	THEN	'min'
														WHEN @i = 6  	THEN	'min'
														WHEN @i = 7  	THEN	'min'
														WHEN @i = 8  	THEN	'%'
														WHEN @i = 9  	THEN	'%'
														WHEN @i = 10  	THEN	'%'
														WHEN @i = 11  	THEN	'%'
														WHEN @i = 12  	THEN	'%'
														WHEN @i = 13  	THEN	'%'
														WHEN @i = 14  	THEN	'%'
														WHEN @i = 15  	THEN	'#'
														WHEN @i = 16  	THEN	'%'
														WHEN @i = 17  	THEN	'%'
														WHEN @i = 18  	THEN	'#'
														WHEN @i = 19  	THEN	'min'
														WHEN @i = 20  	THEN	'min'
														WHEN @i = 21  	THEN	'min'
														WHEN @i = 22  	THEN	'min'
														WHEN @i = 23  	THEN	'min'
														WHEN @i = 24  	THEN	'min'
														WHEN @i = 25  	THEN	'min'
														WHEN @i = 26  	THEN	'min'
														WHEN @i = 27  	THEN	'min'
														WHEN @i = 28  	THEN	'min'
														WHEN @i = 29  	THEN	'min'
														WHEN @i = 30  	THEN	'kg'
														WHEN @i = 31  	THEN	'min'
														WHEN @i = 32  	THEN	'min'
														WHEN @i = 33  	THEN	'min'
														WHEN @i = 34  	THEN	'min'
														WHEN @i = 35  	THEN	'#'
														WHEN @i = 36  	THEN	'min'
														WHEN @i = 37  	THEN	'%'
														WHEN @i = 38 	THEN	'#'
														WHEN @i = 39  	THEN	'min'
														END
		---------------------------------------------------------------------------------------------------------------
		--	Replace with default value if prompt string is not found
		---------------------------------------------------------------------------------------------------------------
		IF	LEN(@vchFormulaEngUnits) = 0
		BEGIN
			SELECT	@vchFormulaEngUnits = @vchFormulaEngUnitsDefault
		END
		-------------------------------------------------------------------------------------------------------------------
		--	i.	Get the Machine formula 	
		-------------------------------------------------------------------------------------------------------------------
		SELECT @vchFormula	= CASE	WHEN @i = 1	 THEN	'SUM(BatchDuration) + SUM(BETSDuration) for GAP Events' 
									WHEN @i = 2	 THEN	'Calendar Time - (Schedule Reduce Duration - Total Batch Status EO - Total BETS Status EO) - Total STNU DownTime' 
									WHEN @i = 3	 THEN	'SUM(BatchUptimeInSec)' 
									WHEN @i = 4  THEN	'SUM(BETSDurationInSecForRpt) where CatDTSched = ''DTSched-STNU''' 
									WHEN @i = 5	 THEN	'SUM(BETSDurationInSecForRpt) where CatDTSched = ''DTSched-UnPlanned'''
									WHEN @i = 6	 THEN	'SUM(BETSDurationInSecForRpt) where CatDTSched = ''DTSched-Planned'''
									WHEN @i = 7	 THEN	'Total DownTime = Total Unplanned DownTime + Total Planned DownTime' 
									WHEN @i = 8  THEN	'''Category'' DT / (Schedule Time - STNU)'
									WHEN @i = 9	 THEN	'Total Batch UptimeYield / Total ScheduleTime * 100' 
									WHEN @i = 10 THEN	'Total Batch UptimeYield / (Total ScheduleTime - Total PlannedDownTime) * 100' 
									WHEN @i = 11 THEN	'Sum of (Batch Uptime * Batch RU) / Sum of Batch UpTime) * 100' 
									WHEN @i = 12 THEN	'Total ScheduleTime  / Calendar Time' 
									WHEN @i = 13 THEN	'MakingSystemPR * MakingSystemRU * MakingSystemSU' 
									WHEN @i = 14 THEN	'SUM(BatchStat)' 
									WHEN @i = 15 THEN	'Total BatchCount - AirpurgeWashoutBatchCount - Transfer BatchCount' 
									WHEN @i = 16 THEN	'(SUM Batch UpTime / SUM Batch BCT Actual) * 100.0' 
									WHEN @i = 17 THEN	'(SUM Batch VolumeInKg * 1.0 / SUM Batch TargetSizeInKg * 1.0) * 100.0' 
									WHEN @i = 18 THEN	'SUM(BETSCount) where BatchStateDesc <> ''EO'' and (Action1Desc <> ''E.O.'' or Action1Desc IS NULL)' 
									WHEN @i = 19 THEN	'SUM(BETSDuration for Rpt) / 60.0 where BatchStateDesc <> ''EO'' and (Action1Desc <> ''E.O.'' or Action1Desc IS NULL)' 
									WHEN @i = 20 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where CatDTType = ''DTType-Operational'' and BatchStateDesc <> ''EO'' and (Action1Desc <> ''E.O.'' or Action1Desc IS NULL)' 
									WHEN @i = 21 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where Action1Desc = ''Minor Stop'''
									WHEN @i = 22 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where Action1Desc = ''Process Failure'''
									WHEN @i = 23 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where BatchStateDesc <> ''EO'' and CatDTMach = ''DTMach-Internal'' and Action1Desc = ''Breakdown'''
									WHEN @i = 24 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 BatchStateDesc <> ''EO'' and CatDTType = ''DTType-Quality'' and (Action1Desc <> ''E.O.'' or Action1Desc IS NULL)' 
									WHEN @i = 25 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where BatchStateDesc <> ''EO'' and CatDTType = ''DTType-Starved'' and (Action1Desc <> ''E.O.'' or Action1Desc IS NULL)' 
									WHEN @i = 26 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where BatchStateDesc <> ''EO'' and CatDTType = ''DTType-Supply'' and (Action1Desc <> ''E.O.'' or Action1Desc IS NULL)' 
									WHEN @i = 27 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where Action1Desc = ''E.O.'' or BatchStateDesc = ''E.O.'')' 
									WHEN @i = 28 THEN	'(SUM(BETSDurationInSec) / 60.0) where CatDTSched and CatDTGroup' 
									WHEN @i = 29 THEN	'(SUM(BETSDurationInSec) / 60.0) where Action1Desc = ''EO'' and BatchStateDesc = ''EO''' 
									WHEN @i = 30 THEN	'SUM(BatchVolumeInKg)' 
									WHEN @i = 31 THEN	'SUM(BatchBCTTargetInSec) / 60.0' 
									WHEN @i = 32 THEN	'SUM(BatchBCTActualInSec) / 60.0' 
									WHEN @i = 33 THEN	'((SUM (Batch BCTActualInSec) - SUM(Batch BCT TargetInSec)) / Count(BatchId)) / 60.0' 
									WHEN @i = 34 THEN	'Start Time - End Time' 
									WHEN @i = 35 THEN	'SUM(BETSCount) where the Category' 
									WHEN @i = 36 THEN	'SUM(BETSDurationInSecForRpt) / 60.0 where the Category' 
									WHEN @i = 37 THEN	'For Planned or UnPlanned Categories = Category / (Schedule Time - Total STNU Time), for the Schedule Reduce Section = Schedule Reduced / Report Time, and for the STNU Section  = STNU / Schedule Time' 
									WHEN @i = 38 THEN	'SUM(BETS Count)' 
									WHEN @i = 39 THEN	'SUM(BETSDurationInSecForRpt) / 60.0' 
									END
		-------------------------------------------------------------------------------------------------------------------
		IF @intMaxStringLength < LEN(@vchFormula)
		BEGIN
			SELECT @intMaxStringLength = LEN(@vchFormula)
		END
		-------------------------------------------------------------------------------------------------------------------
		-- GET COMMENTS
		-------------------------------------------------------------------------------------------------------------------
		SELECT @vchComments =	CASE	WHEN @i = 8  THEN	'PR percent calculcated for each Total in the report header on Summary'
										WHEN @i = 15 THEN	'All Batches - Airpuges and Washouts - Transfer on Summary'
										WHEN @i = 16 THEN	'When (SUM Batch UpTime / SUM Batch BCTActual) > 1.0 then the result must be 100.00 on Summary'
										WHEN @i = 17 THEN	'When (SUM Batch VolumeInKg * 1.0 / SUM Batch TargetSizeInKg * 1.0) > 1.0 then the result must be 100.00 on Summary'
										WHEN @i = 29 THEN	'This column is fiexed in the STNU Section on Summary'
										WHEN @i = 35 THEN	'This is the Stops on the Loss Time Category Section and this total depends on the Category on DDS'
										WHEN @i = 36 THEN	'This is the DownTime on the Loss Time Category Section and this total depends on the Category on DDS'
										WHEN @i = 37 THEN	'This is the Loss on the Loss Time Category Section and this total depends on the Category on DDS'
										WHEN @i = 38 THEN	'This is the Stops Clasification column for the Loss Time Reason Section and it also depends on the Sub Section on DDS'
										WHEN @i = 39 THEN	'This is the Loss Time column for the Loss Time Reason Section and it also depends on the Sub Section on DDS'
										ELSE
											NULL
										END
		-------------------------------------------------------------------------------------------------------------------
		IF @intMaxStringLength < LEN(@vchComments)
		BEGIN
			SELECT @intMaxStringLength = LEN(@vchComments)
		END
		-------------------------------------------------------------------------------------------------------------------
		--	DIVIDE the value by a factor to figure out the number of rows to wrap around 
		-------------------------------------------------------------------------------------------------------------------
		SELECT @intMaxStringLength = ROUND((@intMaxStringLength / 23), 1 )
		-------------------------------------------------------------------------------------------------------------------
		--	INSERT VALUES IN @tblBETSFormulas TABLE
		-------------------------------------------------------------------------------------------------------------------
		INSERT INTO @tblBETSFormulas(
				FormulaMeasurePrompt,
				FormulaMeasure,
				EngUnitsPrompt,
				EngUnitsDesc,
				FormulaInfo,
				Comments,
				MaxLength)	
		VALUES	(@intFormulaMeasurePrompt	,
				@vchFormulaMeasure			,
				@intFormulaEngUnitsPrompt	,
				@vchFormulaEngUnits			,
				@vchFormula					,
				@vchComments				,
				@intMaxStringLength			)
		-------------------------------------------------------------------------------------------------------------------
		--	INCREMENT counter
		-------------------------------------------------------------------------------------------------------------------
		SET @i = @i + 1
	END
	--=================================================================================================================
	-- TRAP Errors
	--=================================================================================================================
	ERRORFinish:
	IF	@intErrorCode > 0
	BEGIN
		INSERT INTO @tblBETSFormulas (ErrorCode, ErrorMsg) VALUES (@intErrorCode, @vchErrorMsg)
	END
	--=================================================================================================================
	-- Return function table
	--=================================================================================================================
 	RETURN 
END
--=====================================================================================================================
-- END FUNCTION
--=====================================================================================================================

