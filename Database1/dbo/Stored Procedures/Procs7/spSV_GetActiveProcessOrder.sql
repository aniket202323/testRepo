CREATE Procedure dbo.spSV_GetActiveProcessOrder
@Path_Id int,
@PP_Id int OUTPUT
AS
Declare @Min_Implied_Sequence int
Select @PP_Id = NULL
Select @PP_Id = PP_Id
  From Production_Plan
  Where Path_Id = @Path_Id
  And PP_Status_Id = 3
If @PP_Id is NULL
  Begin
    Select @Min_Implied_Sequence = min(pp.Implied_Sequence)
      From Production_Plan pp
      Join PrdExec_Path_Status_Detail pepsd on pepsd.Path_Id = pp.Path_Id
      Where pp.Path_Id = @Path_Id
      And pepsd.Sort_Order < (Select Sort_Order From PrdExec_Path_Status_Detail Where Path_Id = @Path_Id and PP_Status_Id = 3)
    Select @PP_Id = PP_Id
      From Production_Plan
      Where Path_Id = @Path_Id
      And Implied_Sequence = @Min_Implied_Sequence
  End
