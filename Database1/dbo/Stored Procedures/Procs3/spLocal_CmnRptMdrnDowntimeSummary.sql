CREATE PROCEDURE [dbo].[spLocal_CmnRptMdrnDowntimeSummary]
@strAreaId NVARCHAR (200) NULL, @strProdLineId NVARCHAR (800) NULL, @strWorkCellId NVARCHAR (MAX) NULL, @strProdId NVARCHAR (MAX) NULL, @vchTimeOption VARCHAR (50) NULL, @dtmStartDateTime DATETIME NULL, @dtmEndDateTime DATETIME NULL, @vchExcludeNPT NVARCHAR (3) NULL, @vchSummaryLevel NVARCHAR (20) NULL, @strCrew NVARCHAR (100) NULL, @strShift NVARCHAR (100) NULL, @strLineStatus NVARCHAR (400) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


