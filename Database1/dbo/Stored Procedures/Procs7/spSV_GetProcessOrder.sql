Create Procedure dbo.spSV_GetProcessOrder
@Process_Order_Id int,
@Process_Order nvarchar(100) OUTPUT,
@PP_Status_Id int OUTPUT,
@Prod_Id int OUTPUT,     
@Block_Number nvarchar(100) OUTPUT,
@Forecast_Start_Date datetime OUTPUT,
@Forecast_End_Date datetime OUTPUT,
@Forecast_Quantity float OUTPUT,
@Production_Rate float OUTPUT,
@Comment_Id int OUTPUT,
@PP_Type_Id int OUTPUT,
@Source_PP_Id int OUTPUT,
@User_General_1 nvarchar(255) OUTPUT,
@User_General_2 nvarchar(255) OUTPUT,
@User_General_3 nvarchar(255) OUTPUT,
@Extended_Info nvarchar(255) OUTPUT,
@Control_Type tinyint OUTPUT,
@Parent_Process_Order nvarchar(100) OUTPUT,
@BOM_Formulation_Id int OUTPUT
AS
Select @Process_Order = pp.Process_Order,
  @PP_Status_Id = pp.PP_Status_Id,
  @Prod_Id = pp.Prod_Id,     
  @Block_Number = pp.Block_Number,
  @Forecast_Start_Date = pp.Forecast_Start_Date,
  @Forecast_End_Date = pp.Forecast_End_Date,
  @Forecast_Quantity = pp.Forecast_Quantity,
  @Production_Rate = pp.Production_Rate,
  @Comment_Id = pp.Comment_Id,
  @PP_Type_Id = pp.PP_Type_Id,
  @Source_PP_Id = pp.Source_PP_Id,
  @User_General_1 = pp.User_General_1,
  @User_General_2 = pp.User_General_2,
  @User_General_3 = pp.User_General_3,
  @Extended_Info = pp.Extended_Info,
  @Control_Type = pp.Control_Type,
  @Parent_Process_Order = parent.Process_Order,
 	 @BOM_Formulation_Id = pp.BOM_Formulation_Id
  From Production_Plan pp
  Left Outer Join Production_Plan parent on parent.PP_Id = pp.Parent_PP_Id
  Where pp.PP_Id = @Process_Order_Id
return(1)
