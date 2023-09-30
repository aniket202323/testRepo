CREATE PROCEDURE dbo.spRS_GetErrorDescription
@Error_Id int = Null,
@Group_Id int
 AS
If @Error_Id Is Null
  Begin
    Select REE.Error_Id, REC.Code_Desc, RER.Response_Id, RER.Response_Desc
    From Return_Error_Codes REC
    Left Join Report_Engine_Errors REE on REE.Error_Id = REC.Code_Value
    Left Join Report_Engine_Responses RER on REE.Response_Id = RER.Response_Id
    Where group_Id = @Group_Id
    and App_Id = 11
    Order By REE.Error_Id
  End
Else
  Begin
    Select REE.Error_Id, REC.Code_Desc, RER.Response_Id, RER.Response_Desc
    From Return_Error_Codes REC
    Left Join Report_Engine_Errors REE on REE.Error_Id = REC.Code_Value
    Left Join Report_Engine_Responses RER on REE.Response_Id = RER.Response_Id
    Where group_Id = @Group_Id
    and App_Id = 11
    and REE.Error_Id = @Error_Id
  End
