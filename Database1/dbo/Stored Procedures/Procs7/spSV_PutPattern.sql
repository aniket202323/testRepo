Create Procedure dbo.spSV_PutPattern
@Transaction_Type int,
@PP_Setup_Id int,
@PP_Setup_Detail_Id int ,
@Target_Dimension_X Float,
@Target_Dimension_Y Float,
@Target_Dimension_Z Float,
@Target_Dimension_A Float,
@Comment_Id int,
@User_General_1 nvarchar(255),
@User_General_2 nvarchar(255),
@User_General_3 nvarchar(255),
@Extended_Info nvarchar(255),
@User_Id int,
@NewDetailId int  = null Output
AS
Declare @Check int
Declare @Element_Number int
Declare @Max_Element_Number int
Declare @Prod_Id int
-- Transaction Types
-- 1 - Insert
-- 2 - Update
-- 3 - Delete
If @Transaction_Type = 1 
  Begin
    Select @Max_Element_Number = max(Element_Number) From Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id
    if @Max_Element_Number is NULL
      Select @Element_Number = 1
    else
      Select @Element_Number = @Max_Element_Number + 1
    Select @Prod_Id = pp.Prod_Id from Production_Plan pp
    Join Production_Setup ps on ps.PP_Id = pp.PP_Id
    Where ps.PP_Setup_Id = @PP_Setup_Id
  End
If @Transaction_Type = 2
  Update Production_Setup_Detail
    Set Target_Dimension_X = @Target_Dimension_X,
    Target_Dimension_Y = @Target_Dimension_Y,
    Target_Dimension_Z = @Target_Dimension_Z,
    Target_Dimension_A = @Target_Dimension_A,
    Comment_Id = @Comment_Id,
    User_General_1 = @User_General_1,
    User_General_2 = @User_General_2,
    User_General_3  = @User_General_3,
    Extended_Info  = @Extended_Info,
    User_Id = @User_Id
  Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
Else If @Transaction_Type = 1
BEGIN
  Insert Into Production_Setup_Detail (
    PP_Setup_Id,
    Target_Dimension_X,
    Target_Dimension_Y,
    Target_Dimension_Z,
    Target_Dimension_A,
    Comment_Id,
    User_General_1,
    User_General_2,
    User_General_3,
    Extended_Info,
    Element_Number,
    Element_Status,
    Prod_Id,
    User_Id)
  Values (
    @PP_Setup_Id,
    @Target_Dimension_X,
    @Target_Dimension_Y,
    @Target_Dimension_Z,
    @Target_Dimension_A,
    @Comment_Id,
    @User_General_1,
    @User_General_2,
    @User_General_3,
    @Extended_Info,
    @Element_Number,
    5,
    @Prod_Id,
    @User_Id)
 	 SELECT @NewDetailId = PP_Setup_Detail_Id From Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id and Element_Number = @Element_Number
END
Else
  Begin
    Select @Check = Comment_Id From Production_Setup_Detail Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
    If @Check Is Not Null
      Update Comments 
        Set ShouldDelete = 1, 
            Comment = '',
            Comment_Text = ''
        Where Comment_Id = @Check
      Delete From Production_Setup_Detail Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
  End
return(1)
