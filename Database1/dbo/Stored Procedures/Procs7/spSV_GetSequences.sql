Create Procedure dbo.spSV_GetSequences
@PP_Id int
AS
Select ps.PP_Setup_Id, ps.Implied_Sequence, ps.Comment_Id, ps.Pattern_Code, ps.PP_Status_Id, 
       ps.Predicted_Remaining_Quantity, ps.Actual_Good_Quantity, ps.Forecast_Quantity, 
       ps.Actual_Repetitions, ps.Pattern_Repititions, 
       ps.Base_Dimension_X, ps.Base_Dimension_Y, ps.Base_Dimension_Z, ps.Base_Dimension_A, 
       ps.Base_General_1, ps.Base_General_2, ps.Base_General_3, ps.Base_General_4, 
       ps.User_General_1, ps.User_General_2, ps.User_General_3, ps.Extended_Info
  From Production_Setup ps
  Where ps.PP_Id = @PP_Id
