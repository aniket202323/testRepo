CREATE Procedure dbo.spSV_CreateChild
@Sheet_Id int,
@Path_Id int,
@PP_Id int,
@PP_Setup_Id int
AS
If @Path_Id = 0
  Select @Path_Id = NULL
If @PP_Setup_Id = 0
  Select @PP_Setup_Id = NULL
if @Path_Id is NOT NULL
  Begin
    Select Distinct pep.Path_Id, pep.Path_Code
      From PrdExec_Paths pep
      Join PrdExec_Path_Products pepp on pepp.Path_Id = pep.Path_Id
      Where pepp.Path_Id <> @Path_Id
      And pepp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Path_Id = @Path_Id)
      Order By pep.Path_Code
  End
else if @Sheet_Id is NOT NULL
  Begin
    Select Distinct pep.Path_Id, pep.Path_Code
      From PrdExec_Paths pep
      Join PrdExec_Path_Products pepp on pepp.Path_Id = pep.Path_Id
      Where pep.Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
      Order By pep.Path_Code
  End
if @PP_Setup_Id is NULL
  Select Forecast_Quantity - (Select Coalesce(Sum(Coalesce(Forecast_Quantity, 0)), 0) From Production_Plan Where Parent_PP_Id = @PP_Id) as 'Forecast_Quantity',
         Forecast_Start_Date, Forecast_End_Date, Process_Order
    From Production_Plan
    Where PP_Id = @PP_Id
else
  Select Forecast_Quantity - (Select Coalesce(Sum(Coalesce(Forecast_Quantity, 0)), 0) From Production_Setup Where Parent_PP_Setup_Id = @PP_Setup_Id) as 'Forecast_Quantity',
         Pattern_Code
    From Production_Setup
    Where PP_Setup_Id = @PP_Setup_Id
if @Path_Id is NOT NULL
  Begin
    Select pp.PP_Id, pp.Process_Order
      From Production_Plan pp
      Join PrdExec_Path_Status_Detail pepsd on pepsd.Path_Id = pp.Path_Id and pepsd.PP_Status_Id = pp.PP_Status_Id
      Where pp.Path_Id = @Path_Id
      And pepsd.Sort_Order <= (Select Sort_Order From PrdExec_Path_Status_Detail Where Path_Id = @Path_Id and PP_Status_Id = 3)
      Order By pp.Process_Order
  End
else if @Sheet_Id is NOT NULL
  Begin
    Select pp.PP_Id, pp.Process_Order
      From Production_Plan pp
      Join PrdExec_Path_Status_Detail pepsd on pepsd.Path_Id = pp.Path_Id and pepsd.PP_Status_Id = pp.PP_Status_Id
     	 Where pp.Path_Id is NULL
      And pp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Prod_Id = Prod_Id and Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
      And pepsd.Sort_Order <= (Select Sort_Order From PrdExec_Path_Status_Detail Where Path_Id = @Path_Id and PP_Status_Id = 3)
      Order By pp.Process_Order
  End
Select Count(*) as SequenceCount
  From Production_Setup
  Where PP_Id = @PP_Id
Select PP_Setup_Id, Pattern_Code
  From Production_Setup
  Where PP_Id = @PP_Id
  Order by Pattern_Code
