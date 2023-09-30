--
/*  
EXECUTE dbo.spBF_GetLineOEEKPIData --
 	 @LineList = '1',
 	 @StartTime = '09/11/2016',
 	 @EndTime = '09/12/2016',
 	 @TimeSelection = 0,
 	 @FilterNonProductiveTime = 1,
 	 @InTimeZone = NULL,
 	 @SortOrder = 3,
 	 @AscDesc = 1,
 	 @ReturnType = 2,
 	 @pageSize = 9999,
 	 @pageNum = 1,
 	 @MaxResultsReturned = 1000,
 	 @FilterType = 0;
*/
CREATE PROCEDURE [dbo].[spBF_GetLineOEEKPIData]
 	 --@LineList                nvarchar(max), 	  	  	  	 -- Required (Null returns all Lines)
 	 @UnitList NVARCHAR(MAX),
 	 @StartTime DATETIME = NULL, 	  	   -- Used When @TimeSelection = 0 (user Defined time)
 	 @EndTime DATETIME = NULL, 	  	   -- Used When @TimeSelection = 0 (user Defined time)
 	 @TimeSelection INT = 0, 	  	  	   -- 0 - Use Times Passed In, 1 - Current Day,2 - Previous Day,3 - Current Week,4 - Previous Week
 	 @FilterNonProductiveTime INT = 0, -- 1 = remove NPT from results
 	 @InTimeZone NVARCHAR(200) = NULL, -- timeZone to return data in (defaults to department if not supplied)
 	 @SortOrder INT = 1, 	  	  	  	   --  PercentOEE(!= 1,2,3,4),1 - PerformanceRate,2 - QualityRate,3 - AvailableRate,4 Unit Description
 	 @AscDesc INT = 0, 	  	  	  	   -- 0 - Ascending
 	 @ReturnType INT = 0, 	  	  	   -- 0 - Return all results, 1 -  Return Results For EA (limited results), 2 -  Return limited results For Children (requires 1 line Id),3 - return clockon data
 	 @pageSize INT = 4, 	  	  	  	   -- # Results returned
 	 @pageNum INT = 1, 	  	  	  	   -- Offest fro results
 	 @MaxResultsReturned INT = 10, 	   -- Maximum rows returned used for sort (@pageSize should be > this number)
 	 @FilterType INT = 0, 	  	  	   -- 0 - no filter,1 clocked on,2 Clocked Off,3 Machine Running,4 Machine Down
 	 @Summarize INT = 0, 	  	  	  	   --if 1 willgive summary of all lines
 	 @TotalRowcount INT OUTPUT
AS
/* ##### spBF_GetLineOEEKPIData #####
Description  	  : Returns data for the donuts shown in Supervisory screen(Summary & line level
Creation Date  	  : if any
Created By  	  : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	  	  	 Comments  	    	  
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 F28159 	  	  	  	  	  	  	 Added logic to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, Downtime PL and toggle calculation based on OEE calculation type (Classic or Time Based)
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	  	  	 Passed actual filter for NPT
2018-06-08 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	  	  	 Added MachineCount in resultset
2018-06-20 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE77740 	  	  	  	  	  	  	 Removed cap for PerformanceRate and PercentOEE
2022-01-27 	  	  	 Karthik 	  	  	  	 PA2022 DE175684 	  	  	  	  	  	  	 Rounding Issue Fixed
2022-03-04 	  	  	 Karthik 	  	  	  	 8.2 DE177593 	  	  	  	  	  	  	 Rounding Issue Fixed
*/
SET NOCOUNT ON;
DECLARE @low INT = 50;
DECLARE @Moderate INT = 85;
DECLARE @Good INT = 60;
DECLARE @startRow INT;
DECLARE @endRow INT;
DECLARE @NewPageNum INT;
SET @pageNum = COALESCE(@pageNum, 1);
SET @pageSize = COALESCE(@pageSize, 20);
SET @NewPageNum = @NewPageNum - 1;
SET @startRow = COALESCE(@NewPageNum * @pageSize, 0) + 1;
SET @endRow = @startRow + @pageSize - 1;
SET @TimeSelection = COALESCE(@TimeSelection, 0);
SET @FilterNonProductiveTime = COALESCE(@FilterNonProductiveTime, 0);
SET @SortOrder = COALESCE(@SortOrder, 1);
SET @AscDesc = COALESCE(@AscDesc, 0);
SET @ReturnType = COALESCE(@ReturnType, 0);
IF RTRIM(LTRIM(@InTimeZone)) = ''
 	 SET @InTimeZone = NULL;
SET @InTimeZone = COALESCE(@InTimeZone, 'UTC');
IF @ReturnType NOT IN ( 2, 3 )
 	 SET @FilterType = 0;
DECLARE @LineRows INT,
 	  	 @Row INT,
 	  	 @LineId INT,
 	  	 @OEECalcType INT,
 	  	 @CapRates TINYINT;
DECLARE @Lines TABLE
(
 	 RowID INT IDENTITY,
 	 LineId INT NULL,
 	 LineDesc NVARCHAR(50),
 	 OEEMode INT
);
DECLARE @FilteredLines TABLE
(
 	 RowID INT IDENTITY,
 	 LineId INT NULL,
 	 LineDesc NVARCHAR(50),
 	 OEEMode INT
);
DECLARE @PagedLines TABLE
(
 	 RowID INT IDENTITY,
 	 LineId INT NULL,
 	 LineDesc NVARCHAR(50),
 	 OEEMode INT
);
--DECLARE @UnitList  	  nvarchar(max)
DECLARE @Linesummary TABLE
(
 	 LineDesc NVARCHAR(50) NULL,
 	 UnitId INT NULL,
 	 UnitDesc NVARCHAR(50) NULL,
 	 UnitOrder INT NULL,
 	 ProductionAmount FLOAT NULL,
 	 IdealProductionAmount FLOAT NULL,
 	 ActualSpeed FLOAT NULL,
 	 IdealSpeed FLOAT NULL,
 	 PerformanceRate FLOAT NULL,
 	 WasteAmount FLOAT NULL,
 	 QualityRate FLOAT NULL,
 	 PerformanceTime FLOAT DEFAULT 0,
 	 RunTime FLOAT DEFAULT 0,
 	 LoadingTime FLOAT DEFAULT 0,
 	 AvailableRate FLOAT NULL,
 	 PercentOEE FLOAT DEFAULT 0,
 	 StartTime DATETIME,
 	 EndTime DATETIME,
 	 LineStatus INT,
 	 NPT FLOAT DEFAULT 0,
 	 DowntimeA FLOAT DEFAULT 0,
 	 DowntimeP FLOAT DEFAULT 0,
 	 DowntimeQ FLOAT DEFAULT 0,
 	 DowntimePL FLOAT DEFAULT 0,
 	 OEEMode INT DEFAULT 0,
 	 MachineCount INT DEFAULT 0
);
DECLARE @Units TABLE
(
 	 PUId INT,
 	 OEEMode INT,
 	 UnitStatus INT
);
DECLARE @FilteredUnits TABLE
(
 	 PUId INT
);
SELECT @CapRates = dbo.fnCMN_OEERateIsCapped();
DECLARE @Summary TABLE
(
 	 Line NVARCHAR(100),
 	 UnitId INT,
 	 UnitDesc NVARCHAR(100),
 	 UnitOrder INT,
 	 ProductionAmount FLOAT,
 	 IdealProductionAmount FLOAT,
 	 ActualSpeed FLOAT,
 	 IdealSpeed FLOAT,
 	 PerformanceRate FLOAT,
 	 WasteAmount FLOAT,
 	 QualityRate FLOAT,
 	 PerformanceTime FLOAT,
 	 RunTime FLOAT,
 	 LoadingTime FLOAT,
 	 AvailableRate FLOAT,
 	 PercentOEE FLOAT,
 	 NPT FLOAT DEFAULT 0,
 	 DowntimeA FLOAT DEFAULT 0,
 	 DowntimeP FLOAT DEFAULT 0,
 	 DowntimeQ FLOAT DEFAULT 0,
 	 DowntimePL FLOAT DEFAULT 0,
 	 OEEMode INT DEFAULT 0,
 	 MachineCount INT DEFAULT 0
);
DECLARE @LineList NVARCHAR(MAX);
SET @LineList = NULL;
INSERT INTO @Units
 	 (
 	  	 PUId
 	 )
SELECT col1
FROM dbo.fn_SplitString(@UnitList, ',');
UPDATE @Units
SET OEEMode = 1;
UPDATE a
SET a.OEEMode = COALESCE(b.Value, 1)
FROM @Units AS a
JOIN dbo.Table_Fields_Values AS b
 	 ON b.KeyId = a.PUId
 	    AND b.Table_Field_Id = -91
 	    AND b.TableId = 43;
UPDATE a
SET a.UnitStatus = COALESCE(b.TEDet_Id, 0)
FROM @Units AS a
LEFT JOIN dbo.Timed_Event_Details AS b
 	 ON b.PU_Id = a.PUId
 	    AND b.End_Time IS NULL;
UPDATE @Units
SET UnitStatus = 1
WHERE UnitStatus > 0;
INSERT INTO @Linesummary
 	 (
 	  	 LineDesc,
 	  	 UnitId,
 	  	 UnitDesc,
 	  	 UnitOrder,
 	  	 ProductionAmount,
 	  	 IdealProductionAmount,
 	  	 ActualSpeed,
 	  	 IdealSpeed,
 	  	 PerformanceRate,
 	  	 WasteAmount,
 	  	 QualityRate,
 	  	 PerformanceTime,
 	  	 RunTime,
 	  	 LoadingTime,
 	  	 AvailableRate,
 	  	 PercentOEE,
 	  	 NPT,
 	  	 DowntimeA,
 	  	 DowntimeP,
 	  	 DowntimeQ,
 	  	 DowntimePL,
 	  	 OEEMode,
 	  	 MachineCount
 	 )
EXECUTE dbo.spBF_OEEGetData_MasterUnits @UnitList = @UnitList,
 	  	  	  	  	  	  	  	  	  	 @StartTime = @StartTime,
 	  	  	  	  	  	  	  	  	  	 @EndTime = @EndTime,
 	  	  	  	  	  	  	  	  	  	 @FilterNonProductiveTime = @FilterNonProductiveTime,
 	  	  	  	  	  	  	  	  	  	 @InTimeZone = @InTimeZone,
 	  	  	  	  	  	  	  	  	  	 @ReturnLineData = @ReturnType;
UPDATE @Linesummary
SET StartTime = @StartTime,
 	 EndTime = @EndTime;
DECLARE @UnitCount INT,
 	  	 @DownUnitCount INT;
--<When a line has units with different OEEModes we need to sum up all the values for those units.>
SELECT LineDesc,
 	    UnitId,
 	    UnitDesc,
 	    UnitOrder,
 	    ProductionAmount,
 	    IdealProductionAmount,
 	    ActualSpeed,
 	    IdealSpeed,
 	    PerformanceRate,
 	    WasteAmount,
 	    QualityRate,
 	    PerformanceTime,
 	    RunTime,
 	    LoadingTime,
 	    AvailableRate,
 	    PercentOEE,
 	    StartTime,
 	    EndTime,
 	    LineStatus,
 	    NPT,
 	    DowntimeA,
 	    DowntimeP,
 	    DowntimeQ,
 	    DowntimePL,
 	    OEEMode,
 	    MachineCount
INTO #tmplineSummary
FROM @Linesummary;
DELETE FROM @Linesummary;
INSERT INTO @Linesummary
 	 (
 	  	 LineDesc,
 	  	 UnitId,
 	  	 UnitDesc,
 	  	 UnitOrder,
 	  	 ProductionAmount,
 	  	 IdealProductionAmount,
 	  	 ActualSpeed,
 	  	 IdealSpeed,
 	  	 PerformanceRate,
 	  	 WasteAmount,
 	  	 QualityRate,
 	  	 PerformanceTime,
 	  	 RunTime,
 	  	 LoadingTime,
 	  	 AvailableRate,
 	  	 PercentOEE,
 	  	 NPT,
 	  	 DowntimeA,
 	  	 DowntimeP,
 	  	 DowntimeQ,
 	  	 DowntimePL,
 	  	 OEEMode,
 	  	 MachineCount
 	 )
SELECT LineDesc,
 	    UnitId,
 	    UnitDesc,
 	    UnitOrder,
 	    SUM(ProductionAmount),
 	    SUM(IdealProductionAmount),
 	    SUM(ActualSpeed),
 	    SUM(IdealSpeed),
 	    SUM(PerformanceRate),
 	    SUM(WasteAmount),
 	    SUM(QualityRate),
 	    SUM(PerformanceTime),
 	    SUM(RunTime),
 	    SUM(LoadingTime),
 	    SUM(AvailableRate),
 	    SUM(PercentOEE),
 	    SUM(NPT),
 	    SUM(DowntimeA),
 	    SUM(DowntimeP),
 	    SUM(DowntimeQ),
 	    SUM(DowntimePL),
 	    1,
 	    SUM(MachineCount)
FROM #tmplineSummary
GROUP BY LineDesc,
 	  	  UnitId,
 	  	  UnitDesc,
 	  	  UnitOrder;
DROP TABLE #tmplineSummary;
UPDATE A
SET A.OEEMode = P.OEEMode
FROM @Linesummary AS A
JOIN @PagedLines AS P
 	 ON P.LineId = A.UnitId;
--<TIME BASED CALCULATION>--
UPDATE A
SET A.AvailableRate = CASE
 	  	  	  	  	  	   WHEN (A.LoadingTime - A.DowntimePL) <= 0 THEN 0
 	  	  	  	  	  	   ELSE (CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA AS FLOAT) / CAST(A.LoadingTime - A.DowntimePL AS FLOAT))
 	  	  	  	  	   END * 100,
 	 A.PerformanceRate = CASE
 	  	  	  	  	  	  	 WHEN (A.LoadingTime - A.DowntimePL - A.DowntimeA) <= 0 THEN 0
 	  	  	  	  	  	  	 ELSE (CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP AS FLOAT) / CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA AS FLOAT))
 	  	  	  	  	  	 END * 100,
 	 A.QualityRate = CASE
 	  	  	  	  	  	 WHEN (A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP) <= 0 THEN 0
 	  	  	  	  	  	 ELSE (CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP - A.DowntimeQ AS FLOAT) / CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP AS FLOAT))
 	  	  	  	  	 END * 100
FROM @Linesummary AS A;
--WHERE OEEMode  = 4
UPDATE @Linesummary
SET PerformanceRate = CASE
 	  	  	  	  	  	   WHEN PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	   ELSE PerformanceRate
 	  	  	  	  	   END;
UPDATE @Linesummary
SET PercentOEE = ((PerformanceRate / 100) * (QualityRate / 100) * (AvailableRate / 100)) * 100;
--</TIME BASED CALCULATION>--
IF @ReturnType = 0
 	 BEGIN
 	  	 IF @Summarize = 0
 	  	  	 BEGIN
 	  	  	  	 SELECT Line = s.LineDesc,
 	  	  	  	  	    s.UnitId,
 	  	  	  	  	    s.UnitDesc,
 	  	  	  	  	    s.UnitOrder,
 	  	  	  	  	    s.ProductionAmount,
 	  	  	  	  	    s.IdealProductionAmount,
 	  	  	  	  	    s.ActualSpeed,
 	  	  	  	  	    s.IdealSpeed,
 	  	  	  	  	    PerformanceRate = CASE
 	  	  	  	  	  	  	  	  	  	  	  WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	  	  ELSE s.PerformanceRate
 	  	  	  	  	  	  	  	  	  	  END,
 	  	  	  	  	    s.WasteAmount,
 	  	  	  	  	    QualityRate = CASE
 	  	  	  	  	  	  	  	  	  	  WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	  ELSE s.QualityRate
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	  	    s.PerformanceTime,
 	  	  	  	  	    s.RunTime,
 	  	  	  	  	    s.LoadingTime,
 	  	  	  	  	    AvailableRate = CASE
 	  	  	  	  	  	  	  	  	  	    WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	    ELSE s.AvailableRate
 	  	  	  	  	  	  	  	  	    END,
 	  	  	  	  	    PercentOEE = CASE
 	  	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > 100 AND @CapRates = 1 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	 ELSE s.PercentOEE
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	    s.OEEMode,
 	  	  	  	  	    s.MachineCount
 	  	  	  	 FROM @Linesummary AS s
 	  	  	  	 ORDER BY PercentOEE OFFSET @pageSize * (@pageNum - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;
 	  	  	 END;
 	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO @Summary
 	  	  	  	  	 (
 	  	  	  	  	  	 Line,
 	  	  	  	  	  	 UnitId,
 	  	  	  	  	  	 UnitDesc,
 	  	  	  	  	  	 UnitOrder,
 	  	  	  	  	  	 ProductionAmount,
 	  	  	  	  	  	 IdealProductionAmount,
 	  	  	  	  	  	 ActualSpeed,
 	  	  	  	  	  	 IdealSpeed,
 	  	  	  	  	  	 PerformanceRate,
 	  	  	  	  	  	 WasteAmount,
 	  	  	  	  	  	 QualityRate,
 	  	  	  	  	  	 PerformanceTime,
 	  	  	  	  	  	 RunTime,
 	  	  	  	  	  	 LoadingTime,
 	  	  	  	  	  	 AvailableRate,
 	  	  	  	  	  	 PercentOEE,
 	  	  	  	  	  	 NPT,
 	  	  	  	  	  	 DowntimeA,
 	  	  	  	  	  	 DowntimeP,
 	  	  	  	  	  	 DowntimeQ,
 	  	  	  	  	  	 DowntimePL,
 	  	  	  	  	  	 OEEMode,
 	  	  	  	  	  	 MachineCount
 	  	  	  	  	 )
 	  	  	  	 SELECT 'Dept',
 	  	  	  	  	    1,
 	  	  	  	  	    'All',
 	  	  	  	  	    1,
 	  	  	  	  	    SUM(s.ProductionAmount),
 	  	  	  	  	    SUM(s.IdealProductionAmount),
 	  	  	  	  	    ActualSpeed = CASE
 	  	  	  	  	  	  	  	  	  	  WHEN SUM(s.RunTime) = 0 THEN 0
 	  	  	  	  	  	  	  	  	  	  ELSE SUM(s.ProductionAmount) / SUM(s.RunTime)
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	  	    IdealSpeed = CASE
 	  	  	  	  	  	  	  	  	  	 WHEN SUM(s.RunTime) = 0 THEN 0
 	  	  	  	  	  	  	  	  	  	 ELSE SUM(s.IdealProductionAmount) / SUM(s.RunTime)
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	    dbo.fnGEPSPerformance(SUM(s.ProductionAmount), SUM(s.IdealProductionAmount), @CapRates),
 	  	  	  	  	    SUM(s.WasteAmount),
 	  	  	  	  	    dbo.fnGEPSQuality(SUM(s.ProductionAmount), SUM(s.WasteAmount), @CapRates),
 	  	  	  	  	    SUM(s.PerformanceTime),
 	  	  	  	  	    SUM(s.RunTime),
 	  	  	  	  	    SUM(s.LoadingTime),
 	  	  	  	  	    CASE
 	  	  	  	  	  	    WHEN SUM(s.LoadingTime) = 0 THEN 0
 	  	  	  	  	  	    ELSE
 	  	  	  	  	  	  	    CASE
 	  	  	  	  	  	  	  	    WHEN ((SUM(s.RunTime) + SUM(s.PerformanceTime)) / SUM(s.LoadingTime)) * 100 > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	    ELSE ((SUM(s.RunTime) + SUM(s.PerformanceTime)) / SUM(s.LoadingTime)) * 100
 	  	  	  	  	  	  	    END
 	  	  	  	  	    END,
 	  	  	  	  	    0,
 	  	  	  	  	    SUM(s.NPT),
 	  	  	  	  	    SUM(s.DowntimeA),
 	  	  	  	  	    SUM(s.DowntimeP),
 	  	  	  	  	    SUM(s.DowntimeQ),
 	  	  	  	  	    SUM(s.DowntimePL),
 	  	  	  	  	    1,
 	  	  	  	  	    SUM(s.MachineCount)
 	  	  	  	 FROM @Linesummary AS s;
 	  	  	  	 UPDATE A
 	  	  	  	 SET A.AvailableRate = CASE
 	  	  	  	  	  	  	  	  	  	   WHEN (A.LoadingTime - A.DowntimePL) <= 0 THEN 0
 	  	  	  	  	  	  	  	  	  	   ELSE (CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA AS FLOAT) / CAST(A.LoadingTime - A.DowntimePL AS FLOAT))
 	  	  	  	  	  	  	  	  	   END * 100,
 	  	  	  	  	 A.PerformanceRate = CASE
 	  	  	  	  	  	  	  	  	  	  	 WHEN (A.LoadingTime - A.DowntimePL - A.DowntimeA) <= 0 THEN 0
 	  	  	  	  	  	  	  	  	  	  	 ELSE (CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP AS FLOAT) / CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA AS FLOAT))
 	  	  	  	  	  	  	  	  	  	 END * 100,
 	  	  	  	  	 A.QualityRate = CASE
 	  	  	  	  	  	  	  	  	  	 WHEN (A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP) <= 0 THEN 0
 	  	  	  	  	  	  	  	  	  	 ELSE (CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP - A.DowntimeQ AS FLOAT) / CAST(A.LoadingTime - A.DowntimePL - A.DowntimeA - A.DowntimeP AS FLOAT))
 	  	  	  	  	  	  	  	  	 END * 100
 	  	  	  	 FROM @Summary AS A;
 	  	  	  	 UPDATE @Summary
 	  	  	  	 SET PercentOEE = ((PerformanceRate / 100) * (AvailableRate / 100) * (QualityRate / 100)) * 100;
 	  	  	  	 SELECT Line,
 	  	  	  	  	    UnitId,
 	  	  	  	  	    UnitDesc,
 	  	  	  	  	    UnitOrder,
 	  	  	  	  	    ProductionAmount,
 	  	  	  	  	    IdealProductionAmount,
 	  	  	  	  	    ActualSpeed,
 	  	  	  	  	    IdealSpeed,
 	  	  	  	  	    PerformanceRate,
 	  	  	  	  	    WasteAmount,
 	  	  	  	  	    QualityRate,
 	  	  	  	  	    PerformanceTime,
 	  	  	  	  	    RunTime,
 	  	  	  	  	    LoadingTime,
 	  	  	  	  	    AvailableRate,
 	  	  	  	  	    PercentOEE,
 	  	  	  	  	    OEEMode = (SELECT CASE WHEN COUNT(0) = COUNT(CASE WHEN OEEMode = 4 THEN 1 ELSE NULL END) THEN 1 ELSE 0 END FROM @PagedLines),
 	  	  	  	  	    MachineCount
 	  	  	  	 FROM @Summary
 	  	  	  	 ORDER BY CASE
 	  	  	  	  	  	  	  WHEN @SortOrder = 4 THEN Line
 	  	  	  	  	  	  END,
 	  	  	  	  	  	  CASE
 	  	  	  	  	  	  	  WHEN @SortOrder = 1 THEN PerformanceRate
 	  	  	  	  	  	  	  WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	  	  	  WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	  	  	  ELSE PercentOEE
 	  	  	  	  	  	  END DESC,
 	  	  	  	  	  	  Line ASC OFFSET @pageSize * (@pageNum - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;
 	  	  	 END;
 	 END;
SELECT @TotalRowcount = COUNT(0)
FROM @Linesummary;
ReturnData:
IF @ReturnType = 3
 	 BEGIN
 	  	 DELETE FROM @Linesummary
 	  	 WHERE UnitDesc = 'All';
 	 END;
SET ROWCOUNT @MaxResultsReturned;
UPDATE @Linesummary
SET AvailableRate = CASE
 	  	  	  	  	  	 WHEN AvailableRate < 0 THEN 0
 	  	  	  	  	  	 ELSE AvailableRate
 	  	  	  	  	 END,
 	 PerformanceRate = CASE
 	  	  	  	  	  	   WHEN PerformanceRate < 0 THEN 0
 	  	  	  	  	  	   ELSE PerformanceRate
 	  	  	  	  	   END,
 	 QualityRate = CASE
 	  	  	  	  	   WHEN QualityRate < 0 THEN 0
 	  	  	  	  	   ELSE QualityRate
 	  	  	  	   END;
UPDATE @Summary
SET AvailableRate = CASE
 	  	  	  	  	  	 WHEN AvailableRate < 0 THEN 0
 	  	  	  	  	  	 ELSE AvailableRate
 	  	  	  	  	 END,
 	 PerformanceRate = CASE
 	  	  	  	  	  	   WHEN PerformanceRate < 0 THEN 0
 	  	  	  	  	  	   ELSE PerformanceRate
 	  	  	  	  	   END,
 	 QualityRate = CASE
 	  	  	  	  	   WHEN QualityRate < 0 THEN 0
 	  	  	  	  	   ELSE QualityRate
 	  	  	  	   END;
UPDATE @Summary
SET PercentOEE = ((PerformanceRate / 100) * (AvailableRate / 100) * (QualityRate / 100)) * 100;
UPDATE @Linesummary
SET PercentOEE = ((PerformanceRate / 100) * (AvailableRate / 100) * (QualityRate / 100)) * 100;
IF @ReturnType IN ( 1, 2 )
 	 BEGIN
 	  	 IF @ReturnType = 2 -- This is Unit Data so we want the unit desc
 	  	  	 UPDATE @Linesummary
 	  	  	 SET LineDesc = UnitDesc;
 	  	 IF @AscDesc = 1
 	  	  	 SELECT Line = s.LineDesc,
 	  	  	  	    LineId = s.UnitId,
 	  	  	  	    s.StartTime,
 	  	  	  	    s.EndTime,
 	  	  	  	    PerformanceRate = CASE
 	  	  	  	  	  	  	  	  	  	  WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.PerformanceRate, 0), 0)
 	  	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.PerformanceRate, 0)
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	    QualityRate = CASE
 	  	  	  	  	  	  	  	  	  WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.QualityRate, 0), 0)
 	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.QualityRate, 0)
 	  	  	  	  	  	  	  	  END,
 	  	  	  	    AvailableRate = CASE
 	  	  	  	  	  	  	  	  	    WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	    --ELSE coalesce(Round(s.AvailableRate,0),0)
 	  	  	  	  	  	  	  	  	    ELSE COALESCE(s.AvailableRate, 0)
 	  	  	  	  	  	  	  	    END,
 	  	  	  	    PercentOEE = CASE
 	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	 --ELSE COALESCE(ROUND(s.PercentOEE, 0), 0)
 	  	  	  	  	  	  	  	  	 ELSE COALESCE(s.PercentOEE, 0)
 	  	  	  	  	  	  	  	 END,
 	  	  	  	    PerformanceThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    QualityThreshold = CASE
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    AvailableThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	 ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    OEEThreshold = CASE
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	   END,
 	  	  	  	    s.LineStatus,
 	  	  	  	    s.OEEMode,
 	  	  	  	    s.MachineCount
 	  	  	 FROM @Linesummary AS s
 	  	  	 ORDER BY CASE
 	  	  	  	  	  	  WHEN @SortOrder = 4 THEN s.LineDesc
 	  	  	  	  	  END,
 	  	  	  	  	  CASE
 	  	  	  	  	  	  WHEN @SortOrder = 1 THEN PerformanceRate
 	  	  	  	  	  	  WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	  	  WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	  	  ELSE PercentOEE
 	  	  	  	  	  END DESC,
 	  	  	  	  	  s.LineDesc ASC OFFSET @pageSize * (@pageNum - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;
 	  	 ELSE
 	  	  	 SELECT Line = s.LineDesc,
 	  	  	  	    LineId = s.UnitId,
 	  	  	  	    s.StartTime,
 	  	  	  	    s.EndTime,
 	  	  	  	    PerformanceRate = CASE
 	  	  	  	  	  	  	  	  	  	  WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.PerformanceRate, 0), 0)
 	  	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.PerformanceRate, 0)
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	    QualityRate = CASE
 	  	  	  	  	  	  	  	  	  WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.QualityRate, 0), 0)
 	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.QualityRate, 0)
 	  	  	  	  	  	  	  	  END,
 	  	  	  	    AvailableRate = CASE
 	  	  	  	  	  	  	  	  	    WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	    --ELSE coalesce(Round(s.AvailableRate,0),0)
 	  	  	  	  	  	  	  	  	    ELSE COALESCE(s.AvailableRate, 0)
 	  	  	  	  	  	  	  	    END,
 	  	  	  	    PercentOEE = CASE
 	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	 --ELSE COALESCE(ROUND(s.PercentOEE, 0), 0)
 	  	  	  	  	  	  	  	  	 ELSE COALESCE(s.PercentOEE, 0)
 	  	  	  	  	  	  	  	 END,
 	  	  	  	    PerformanceThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    QualityThreshold = CASE
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    AvailableThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	 ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    OEEThreshold = CASE
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	   END,
 	  	  	  	    s.LineStatus,
 	  	  	  	    s.OEEMode,
 	  	  	  	    s.MachineCount
 	  	  	 FROM @Linesummary AS s
 	  	  	 ORDER BY CASE
 	  	  	  	  	  	  WHEN @SortOrder = 4 THEN s.LineDesc
 	  	  	  	  	  END,
 	  	  	  	  	  CASE
 	  	  	  	  	  	  WHEN @SortOrder = 1 THEN PerformanceRate
 	  	  	  	  	  	  WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	  	  WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	  	  ELSE PercentOEE
 	  	  	  	  	  END ASC,
 	  	  	  	  	  s.LineDesc ASC OFFSET @pageSize * (@pageNum - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;
 	 END;
IF @ReturnType = 3
 	 BEGIN
 	  	 DELETE FROM @Linesummary
 	  	 WHERE UnitDesc = 'All';
 	  	 IF @AscDesc = 1
 	  	  	 SELECT Line = s.LineDesc,
 	  	  	  	    Unit = s.UnitDesc,
 	  	  	  	    UnitId = s.UnitId,
 	  	  	  	    s.StartTime,
 	  	  	  	    s.EndTime,
 	  	  	  	    PerformanceRate = CASE
 	  	  	  	  	  	  	  	  	  	  WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.PerformanceRate, 0), 0)
 	  	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.PerformanceRate, 0)
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	    QualityRate = CASE
 	  	  	  	  	  	  	  	  	  WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.QualityRate, 0), 0)
 	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.QualityRate, 0)
 	  	  	  	  	  	  	  	  END,
 	  	  	  	    AvailableRate = CASE
 	  	  	  	  	  	  	  	  	    WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	    --ELSE coalesce(Round(s.AvailableRate,0),0)
 	  	  	  	  	  	  	  	  	    ELSE COALESCE(s.AvailableRate, 0)
 	  	  	  	  	  	  	  	    END,
 	  	  	  	    PercentOEE = CASE
 	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	 --ELSE COALESCE(ROUND(s.PercentOEE, 0), 0)
 	  	  	  	  	  	  	  	  	 ELSE COALESCE(s.PercentOEE, 0)
 	  	  	  	  	  	  	  	 END,
 	  	  	  	    ClockedOn = CASE
 	  	  	  	  	  	  	  	    WHEN a.UserId IS NULL THEN 0
 	  	  	  	  	  	  	  	    ELSE 1
 	  	  	  	  	  	  	    END,
 	  	  	  	    Operator = CASE
 	  	  	  	  	  	  	  	   WHEN a.UserId IS NOT NULL THEN u.Username
 	  	  	  	  	  	  	  	   ELSE NULL
 	  	  	  	  	  	  	   END,
 	  	  	  	    MachineRunning = CASE
 	  	  	  	  	  	  	  	  	  	 WHEN c.TEDet_Id IS NULL THEN 1
 	  	  	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    PerformanceThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    QualityThreshold = CASE
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    AvailableThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	 ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    OEEThreshold = CASE
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	   END,
 	  	  	  	    s.OEEMode,
 	  	  	  	    s.MachineCount
 	  	  	 FROM @Linesummary AS s
 	  	  	 LEFT JOIN dbo.User_Equipment_Assignment AS a
 	  	  	  	 ON a.EquipmentId = s.UnitId
 	  	  	  	    AND a.EndTime IS NULL
 	  	  	 LEFT JOIN dbo.Users AS u
 	  	  	  	 ON u.User_Id = a.UserId
 	  	  	 LEFT JOIN dbo.Timed_Event_Details AS c
 	  	  	  	 ON c.PU_Id = s.UnitId
 	  	  	  	    AND c.End_Time IS NULL
 	  	  	 ORDER BY CASE
 	  	  	  	  	  	  WHEN @SortOrder = 4 THEN s.UnitDesc
 	  	  	  	  	  END,
 	  	  	  	  	  CASE
 	  	  	  	  	  	  WHEN @SortOrder = 1 THEN PerformanceRate
 	  	  	  	  	  	  WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	  	  WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	  	  ELSE PercentOEE
 	  	  	  	  	  END DESC,
 	  	  	  	  	  s.UnitDesc ASC OFFSET @pageSize * (@pageNum - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;
 	  	 ELSE
 	  	  	 SELECT Line = s.LineDesc,
 	  	  	  	    Unit = s.UnitDesc,
 	  	  	  	    UnitId = s.UnitId,
 	  	  	  	    s.StartTime,
 	  	  	  	    s.EndTime,
 	  	  	  	    PerformanceRate = CASE
 	  	  	  	  	  	  	  	  	  	  WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.PerformanceRate, 0), 0)
 	  	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.PerformanceRate, 0)
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	    QualityRate = CASE
 	  	  	  	  	  	  	  	  	  WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	  --ELSE COALESCE(ROUND(s.QualityRate, 0), 0)
 	  	  	  	  	  	  	  	  	  ELSE COALESCE(s.QualityRate, 0)
 	  	  	  	  	  	  	  	  END,
 	  	  	  	    AvailableRate = CASE
 	  	  	  	  	  	  	  	  	    WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	    --ELSE coalesce(Round(s.AvailableRate,0),0)
 	  	  	  	  	  	  	  	  	    ELSE COALESCE(s.AvailableRate, 0)
 	  	  	  	  	  	  	  	    END,
 	  	  	  	    PercentOEE = CASE
 	  	  	  	  	  	  	  	  	 WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	  	  	 --ELSE COALESCE(ROUND(s.PercentOEE, 0), 0)
 	  	  	  	  	  	  	  	  	 ELSE COALESCE(s.PercentOEE, 0)
 	  	  	  	  	  	  	  	 END,
 	  	  	  	    ClockedOn = CASE
 	  	  	  	  	  	  	  	    WHEN a.UserId IS NULL THEN 0
 	  	  	  	  	  	  	  	    ELSE 1
 	  	  	  	  	  	  	    END,
 	  	  	  	    Operator = CASE
 	  	  	  	  	  	  	  	   WHEN a.UserId IS NOT NULL THEN u.Username
 	  	  	  	  	  	  	  	   ELSE NULL
 	  	  	  	  	  	  	   END,
 	  	  	  	    MachineRunning = CASE
 	  	  	  	  	  	  	  	  	  	 WHEN c.TEDet_Id IS NULL THEN 1
 	  	  	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    PerformanceThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	   WHEN s.PerformanceRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    QualityThreshold = CASE
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	   WHEN s.QualityRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	  	   END,
 	  	  	  	    AvailableThreshold = CASE
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	  	  	 WHEN s.AvailableRate > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	  	  	 ELSE 'Poor'
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    OEEThreshold = CASE
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @Moderate THEN 'Good'
 	  	  	  	  	  	  	  	  	   WHEN s.PercentOEE > @low THEN 'Moderate'
 	  	  	  	  	  	  	  	  	   ELSE 'Poor'
 	  	  	  	  	  	  	  	   END,
 	  	  	  	    s.OEEMode,
 	  	  	  	    s.MachineCount
 	  	  	 FROM @Linesummary AS s
 	  	  	 LEFT JOIN dbo.User_Equipment_Assignment AS a
 	  	  	  	 ON a.EquipmentId = s.UnitId
 	  	  	  	    AND a.EndTime IS NULL
 	  	  	 LEFT JOIN dbo.Users AS u
 	  	  	  	 ON u.User_Id = a.UserId
 	  	  	 LEFT JOIN dbo.Timed_Event_Details AS c
 	  	  	  	 ON c.PU_Id = s.UnitId
 	  	  	  	    AND c.End_Time IS NULL
 	  	  	 ORDER BY CASE
 	  	  	  	  	  	  WHEN @SortOrder = 4 THEN s.UnitDesc
 	  	  	  	  	  END,
 	  	  	  	  	  CASE
 	  	  	  	  	  	  WHEN @SortOrder = 1 THEN PerformanceRate
 	  	  	  	  	  	  WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	  	  WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	  	  ELSE PercentOEE
 	  	  	  	  	  END ASC,
 	  	  	  	  	  s.UnitDesc ASC OFFSET @pageSize * (@pageNum - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;
 	 END;
