CREATE PROCEDURE dbo.spXLA_BrowseShift
AS
--SET NOCOUNT OFF --commented out ECR #26008 (mt/8-25-2003) let ProfSVR handle this
SELECT DISTINCT Shift_Desc FROM Crew_Schedule ORDER BY Shift_Desc
