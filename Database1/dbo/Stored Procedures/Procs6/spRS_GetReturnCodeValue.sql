CREATE PROCEDURE dbo.spRS_GetReturnCodeValue 
@AppId int,
@GroupId int,
@Code int
 AS
Select * 
From Return_Error_Codes
Where App_Id = @AppId
and Group_Id = @GroupId
and Code_Value = @Code
