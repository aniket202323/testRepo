CREATE procedure [dbo].[spS88R_CrewList]
AS
select Distinct Crew_desc from crew_schedule Order By Crew_desc
