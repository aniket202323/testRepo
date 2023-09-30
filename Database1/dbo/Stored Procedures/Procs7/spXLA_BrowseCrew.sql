CREATE PROCEDURE dbo.spXLA_BrowseCrew
AS
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003) let ProfSVR handle this
SELECT DISTINCT Crew_Desc FROM Crew_Schedule ORDER BY Crew_Desc
