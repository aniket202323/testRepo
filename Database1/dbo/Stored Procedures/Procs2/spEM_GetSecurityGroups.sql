CREATE PROCEDURE dbo.spEM_GetSecurityGroups
AS
select Group_Id as [key],Group_Desc as Description from Security_Groups 
order by Group_Desc
