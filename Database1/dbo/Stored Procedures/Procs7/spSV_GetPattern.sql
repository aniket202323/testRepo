Create Procedure dbo.spSV_GetPattern
@PP_Setup_Detail_Id int,
@Element_Number int OUTPUT,
@Element_Status tinyint OUTPUT,
@Order_Id int OUTPUT,
@Customer_Id int OUTPUT,
@Prod_Id int OUTPUT,
@Total int OUTPUT,
@Target_Dimension_X real OUTPUT,     
@Target_Dimension_Y real OUTPUT,     
@Target_Dimension_Z real OUTPUT,     
@Target_Dimension_A real OUTPUT,     
@Comment_Id int OUTPUT,
@User_General_1 nvarchar(255) OUTPUT,
@User_General_2 nvarchar(255) OUTPUT,
@User_General_3 nvarchar(255) OUTPUT,
@Extended_Info nvarchar(255) OUTPUT,
@Order_Instructions nvarchar(255) OUTPUT,
@Status_Desc nvarchar(255) OUTPUT,
@Order_Num nvarchar(255) OUTPUT,
@Customer_Code nvarchar(255) OUTPUT,
@Prod_Code nvarchar(255) OUTPUT
AS
Select 
  @Element_Number = psd.Element_Number,
  @Element_Status = Element_Status,
  @Order_Id = co.Order_Id,
  @Customer_Id = c.Customer_Id,
  @Prod_Id = Coalesce(p1.Prod_Id, p2.Prod_Id),
  @Total = 0,
  @Target_Dimension_X = psd.Target_Dimension_X,
  @Target_Dimension_Y = psd.Target_Dimension_Y,
  @Target_Dimension_Z = psd.Target_Dimension_Z,
  @Target_Dimension_A = psd.Target_Dimension_A,
  @Comment_Id = psd.Comment_Id,
  @User_General_1 = psd.User_General_1,
  @User_General_2 = psd.User_General_2,
  @User_General_3  = psd.User_General_3,
  @Extended_Info  = psd.Extended_Info,
  @Order_Instructions = co.Order_Instructions,
  @Status_Desc = ps.ProdStatus_Desc,
  @Order_Num = co.Plant_Order_Number,
  @Customer_Code = c.Customer_Code,
  @Prod_Code = coalesce(p1.Prod_Code, p2.Prod_Code)
  From Production_Setup_Detail psd
  Left Outer Join Products p2 on p2.Prod_Id = psd.Prod_id
  Left Outer Join Customer_Order_Line_Items col on col.Order_Line_Id = psd.Order_Line_Id
  Left Outer Join Products p1 on p1.Prod_Id = col.Prod_id
  Left Outer Join Customer_Orders co on co.Order_Id = col.Order_Id
  Left Outer Join Customer c on c.Customer_ID = co.Customer_Id
  Left Outer Join Production_Status ps on ps.ProdStatus_Id = psd.Element_Status
  Where psd.PP_Setup_Detail_Id = @PP_Setup_Detail_Id
return(1)
