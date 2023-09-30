CREATE PROCEDURE [dbo].[spLocal_CmnRptMdrnDailyTop5]
@strTimeOption NVARCHAR (50) NULL, @dtmStartTime DATETIME NULL, @dtmEndTime DATETIME NULL, @lstProdLine NVARCHAR (MAX) NULL, @intValueStreamFlag INT NULL, @strValueStream NVARCHAR (350) NULL, @lstVSMachines NVARCHAR (MAX) NULL, @lstShift NVARCHAR (MAX) NULL, @lstTeam NVARCHAR (MAX) NULL, @lstKPISelection NVARCHAR (MAX) NULL, @strMajorGroupBy NVARCHAR (200) NULL, @strMinorGroupBy NVARCHAR (200) NULL, @vchExcludeNPT NVARCHAR (3) NULL, @strLineStatus NVARCHAR (400) NULL, @bShowTop5Downtimes NVARCHAR (10) NULL, @bShowTop5Stops NVARCHAR (10) NULL, @bShowTop5Scrap NVARCHAR (10) NULL, @strDTGrouping NVARCHAR (20) NULL, @strDTType NVARCHAR (20) NULL, @strStopsGrouping NVARCHAR (20) NULL, @strStopsType NVARCHAR (20) NULL, @strScrapGrouping NVARCHAR (20) NULL, @strScrapType NVARCHAR (20) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


