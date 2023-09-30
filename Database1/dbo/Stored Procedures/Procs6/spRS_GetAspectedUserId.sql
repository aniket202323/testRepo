CREATE PROCEDURE dbo.spRS_GetAspectedUserId
@SOAUserName varchar(255)
AS
select ub.User_Id  from Users_Aspect_Person uap
 join Person p on uap.Origin1PersonId=p.PersonId
 join  Users_Base ub on uap.User_Id=ub.User_Id 
 where p.S95Id=@SOAUserName
