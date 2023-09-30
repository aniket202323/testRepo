CREATE PROCEDURE [dbo].[spRS_AdminGetSecurityGroups]
AS
Select 
Group_Id, Group_Desc 
From Security_Groups
