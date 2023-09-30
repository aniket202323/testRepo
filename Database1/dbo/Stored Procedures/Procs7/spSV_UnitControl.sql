CREATE Procedure dbo.spSV_UnitControl
@Path_Id int
AS
Select PP_Id, Process_Order
  From Production_Plan
  Where PP_Id IN (
    Select PP_Id 
      From Production_Plan_Starts 
      Where PU_Id = (
        Select PU_Id 
          From PrdExec_Path_Units 
          Where Path_Id = @Path_Id and Is_Schedule_Point = 1))
  And PP_Id NOT IN (
    Select PP_Id 
      From Production_Plan_Starts 
      Where PU_Id in (
        Select PU_Id 
          From PrdExec_Path_Units 
          Where Path_Id = @Path_Id and Is_Schedule_Point <> 1))
  And PP_Id NOT IN (
    Select PP_Id 
      From Production_Plan_Starts 
      Where PU_Id in (
        Select PU_Id 
          From PrdExec_Path_Units 
          Where Path_Id = @Path_Id)
      And End_Time is NULL)
Order By Process_Order ASC
