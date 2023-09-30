CREATE PROCEDURE [dbo].[spLocal_CmnRptEditDailyDefinition]
@intDefinitionId INT NULL, @strValueStream NVARCHAR (200) NULL, @strAreaId NVARCHAR (200) NULL, @strProdLineId NVARCHAR (800) NULL, @strWorkCellId NVARCHAR (MAX) NULL, @strWorkCellSlaveId NVARCHAR (MAX) NULL, @strTimeOption VARCHAR (50) NULL, @strExcludeNPT NVARCHAR (3) NULL, @strlineStatus NVARCHAR (MAX) NULL, @strMajorGroup NVARCHAR (20) NULL, @strMinorGroup NVARCHAR (20) NULL, @intStopsTop5 NVARCHAR (3) NULL, @strStopsPlanned NVARCHAR (3) NULL, @strStopsUnplanned NVARCHAR (3) NULL, @strStopsFault NVARCHAR (3) NULL, @strStopsLocation NVARCHAR (3) NULL, @strStopsReason NVARCHAR (3) NULL, @intDowntimeTop5 NVARCHAR (3) NULL, @strDowntimePlanned NVARCHAR (3) NULL, @strDowntimeUnplanned NVARCHAR (3) NULL, @strDowntimeFault NVARCHAR (3) NULL, @strDowntimeLocation NVARCHAR (3) NULL, @strDowntimeReason NVARCHAR (3) NULL, @intScrapTop5 NVARCHAR (3) NULL, @strScrapManual NVARCHAR (3) NULL, @strScrapAutommatic NVARCHAR (3) NULL, @strScrapFault NVARCHAR (3) NULL, @strScrapLocation NVARCHAR (3) NULL, @strScrapReason NVARCHAR (3) NULL, @intReportTypeId INT NULL, @strKpiList NVARCHAR (MAX) NULL, @strDowntimeDetail NVARCHAR (1000) NULL, @strProductionDetail NVARCHAR (1000) NULL, @strTeam NVARCHAR (200) NULL, @strShift NVARCHAR (200) NULL, @strRawDataExport NVARCHAR (3) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


