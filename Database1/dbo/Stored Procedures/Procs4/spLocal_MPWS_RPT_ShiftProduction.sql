 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ShiftProduction
	
	Date			Version		Build	Author  
	27-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ShiftProduction @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20150101', '20170731'
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ShiftProduction]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@StartTime		DATETIME,
	@EndTime		DATETIME
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
DECLARE
	@DispenseCountG		DECIMAL(10, 3),
	@DispenseCountKG	DECIMAL(10, 3),
	@DispenseCountTotal	DECIMAL(10, 3),
	@DispenseWgtG		DECIMAL(10, 3),
	@DispenseWgtKg		DECIMAL(10, 3);
 
DECLARE @Dispenses TABLE
(
	UOM			VARCHAR(25),
	UOMCounts	INT,
	UOMQty		FLOAT
)
 
;WITH d AS
(
	SELECT DISTINCT
		UPPER(t.Result) UOM,
		COUNT(*) OVER (PARTITION BY t.Result) UOMCounts,
		SUM(ISNULL(ed.Initial_Dimension_X, 0.0)) OVER (PARTITION BY t.Result) UOMQty
	FROM dbo.Event_Details ed
		JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
		JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
		JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
			AND t.Var_Id = v.Var_Id
		JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
		JOIN dbo.Prod_Lines_Base pl ON pu.PL_Id = pl.PL_Id
		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
	WHERE v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
		AND d.Dept_Desc = 'Pre-Weigh'
		AND e.[Timestamp] BETWEEN @StartTime AND @EndTime
)
INSERT @Dispenses (UOM, UOMCounts, UOMQty)
	SELECT
		UOM,
		UOMCounts,
		UOMQty
	FROM d
 
SELECT
	@DispenseCountG = CAST(ISNULL(d.UOMCounts, 0.0) AS DECIMAL(10,3)),
	@DispenseWgtG = CAST(ISNULL(d.UOMQty, 0.0) AS DECIMAL(10,3))
FROM @Dispenses d
WHERE d.UOM = 'G'
 
SELECT
	@DispenseCountKG = CAST(ISNULL(d.UOMCounts, 0.0) AS DECIMAL(10,3)),
	@DispenseWgtKG = CAST(ISNULL(d.UOMQty, 0.0) AS DECIMAL(10,3))
FROM @Dispenses d
WHERE d.UOM = 'KG'
 
 
	
 
SELECT
	StartTime			= @StartTime,
	EndTime				= @EndTime,
	DispenseCountG		= ISNULL(@DispenseCountG, 0.0),
	DispenseCountKG		= ISNULL(@DispenseCountKG, 0.0),
	DispenseCountTotal	= ISNULL(@DispenseCountG, 0.0) + ISNULL(@DispenseCountKG, 0.0),
	DispenseWgtG		= ISNULL(@DispenseWgtG, 0.0),
	DispenseWgtKg		= ISNULL(@DispenseWgtKG, 0.0)						 
 
SET @ErrorCode = 1;
SET @ErrorMessage = 'Success';
	
 
 
