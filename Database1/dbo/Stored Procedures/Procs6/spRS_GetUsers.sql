CREATE PROCEDURE dbo.spRS_GetUsers
AS
Select * 
from users
where System = 0 and Is_Role = 0
Order by username
