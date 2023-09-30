CREATE PROCEDURE dbo.spServer_CmnSavePS
@PU_Id int,
@Start_Time datetime,
@End_Time datetime,
@Prod_Id int,
@Duration float,
@In_Warning float,
@In_Limit float,
@Conf_Index float,
@RSum_Id int OUTPUT
 AS
Insert Into GB_RSum (PU_Id,Start_Time,End_Time,Prod_Id,Duration,In_Warning,In_Limit,Conf_Index)
  Values (@PU_Id,@Start_Time,@End_Time,@Prod_Id,@Duration,@In_Warning,@In_Limit,@Conf_Index)
Select @RSum_Id = Scope_identity()
If @RSum_Id Is Null
  Select @RSum_Id = 0
