CREATE PROCEDURE [dbo].[spLocal_CmnRptDailyReport]
@strTimeOption NVARCHAR (20) NULL, @dtmStartTime DATETIME NULL, @dtmEndTime DATETIME NULL, @lstProdLine NVARCHAR (MAX) NULL, @intValueStreamFlag INT NULL, @strValueStream NVARCHAR (350) NULL, @lstVSMachines NVARCHAR (MAX) NULL, @lstShift NVARCHAR (MAX) NULL, @lstTeam NVARCHAR (MAX) NULL, @lstKPISelection NVARCHAR (MAX) NULL, @strMajorGroupBy NVARCHAR (200) NULL, @strMinorGroupBy NVARCHAR (200) NULL, @vchExcludeNPT NVARCHAR (10) NULL, @bShowTop5Downtimes BIT NULL, @bShowTop5Stops BIT NULL, @bShowTop5Scrap BIT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


