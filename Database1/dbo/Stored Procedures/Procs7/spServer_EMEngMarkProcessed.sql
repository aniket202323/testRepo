CREATE PROCEDURE dbo.spServer_EMEngMarkProcessed
@EMId int
 AS
Update  Email_Messages set EM_Processed = 1 where EM_Id = @EMId
