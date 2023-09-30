Create Procedure dbo.spSV_ListStatus
@Path_Id int,
@Sheet_Id int = NULL,
@Operation bit = NULL,
@PP_Id int = NULL
AS
If @Path_Id = 0
  Select @Path_Id = NULL
If @Sheet_Id = 0
  Select @Sheet_Id = NULL
If @PP_Id = 0
  Select @PP_Id = NULL
--Operation - 1(Add) / 0(Edit)
If @Operation Is NULL
  Select @Operation = 1
Declare @PathsViewableOnSheet Table(Path_Id int)
If @Operation = 1
  INSERT INTO @PathsViewableOnSheet
    Select Path_Id
      From PrdExec_Paths
      Where Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
      Order By Path_Id
Else If @Operation = 0
  INSERT INTO @PathsViewableOnSheet
    Select pep.Path_Id
      From PrdExec_Paths pep
      Join PrdExec_Path_Products pepp on pepp.Path_Id = pep.Path_Id
      Where pepp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
      Order By pep.Path_Id
Select Id = PP_Status_Id, Description = PP_Status_Desc
  From production_plan_statuses
  Order By PP_Status_Desc ASC
Select Id = pep.Path_Id, Description = pep.Path_Code
  From PrdExec_Paths pep
  Where pep.Path_Id in (Select Path_Id From @PathsViewableOnSheet)
  Order By pep.Path_Code ASC
Select Id = PP_Type_Id, Description = PP_Type_Name
  From production_plan_types
  Order By PP_Type_Name ASC
Declare @SourceOrders Table(Id int, Description nvarchar(50))
If @PP_Id > 0
Begin
  INSERT INTO @SourceOrders
    Select Id = PP_Id, Description = Process_Order
    From   Production_Plan
    Where  PP_Id = @PP_Id
  INSERT INTO @SourceOrders
    Select Id = pps.PP_Id, Description = pps.Process_Order
    From   Production_Plan pp
    Join   Production_Plan pps on pps.PP_Id = pp.Source_PP_Id
    Where  pp.PP_Id = @PP_Id
End
Select Id, Description
 	 From @SourceOrders
 	 Order By Description ASC
Select Id = Control_Type_Id, Description = Control_Type_Desc
  From Control_Type
