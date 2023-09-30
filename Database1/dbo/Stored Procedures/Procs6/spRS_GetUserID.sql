CREATE PROCEDURE dbo.spRS_GetUserID
@Username varchar(30)
as
select User_ID from Users where UserName = @Username
