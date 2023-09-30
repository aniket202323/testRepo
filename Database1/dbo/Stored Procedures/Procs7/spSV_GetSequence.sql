Create Procedure dbo.spSV_GetSequence
@PP_Setup_Id int,
@Pattern_Code nvarchar(25) OUTPUT,
@Pattern_Repititions int OUTPUT,
@PP_Status_Id int OUTPUT,
@Forecast_Quantity float OUTPUT,
@Base_Dimension_X real OUTPUT,
@Base_Dimension_Y real OUTPUT,
@Base_Dimension_Z real OUTPUT,
@Base_Dimension_A real OUTPUT,
@Comment_Id int OUTPUT,
@User_General_1 nvarchar(255) OUTPUT,
@User_General_2 nvarchar(255) OUTPUT,
@User_General_3 nvarchar(255) OUTPUT,
@Extended_Info nvarchar(255) OUTPUT,
@Base_General_1 real OUTPUT,
@Base_General_2 real OUTPUT,
@Base_General_3 real OUTPUT,
@Base_General_4 real OUTPUT,
@Parent_Pattern_Code nvarchar(25) OUTPUT
AS
Select @Pattern_Code = ps.Pattern_Code,
  @Pattern_Repititions = ps.Pattern_Repititions,
  @PP_Status_Id = ps.PP_Status_Id,
  @Forecast_Quantity = ps.Forecast_Quantity,
  @Base_Dimension_X = ps.Base_Dimension_X,
  @Base_Dimension_Y = ps.Base_Dimension_Y,
  @Base_Dimension_Z = ps.Base_Dimension_Z,
  @Base_Dimension_A = ps.Base_Dimension_A,
  @Comment_Id = ps.Comment_Id,
  @User_General_1 = ps.User_General_1,
  @User_General_2 = ps.User_General_2,
  @User_General_3 = ps.User_General_3,
  @Extended_Info  = ps.Extended_Info,
  @Base_General_1 = ps.Base_General_1,
  @Base_General_2 = ps.Base_General_2,
  @Base_General_3 = ps.Base_General_3,
  @Base_General_4 = ps.Base_General_4,
  @Parent_Pattern_Code = parent.Pattern_Code
  From Production_Setup ps
  Left Outer Join Production_Setup parent on parent.PP_Setup_Id = ps.Parent_PP_Setup_Id
  Where ps.PP_Setup_Id = @PP_Setup_Id
return(1)
