Create Procedure dbo.spSV_MovePattern
@PP_Setup_Detail_Id int,
@Operation int
AS
Declare @This_PP_Setup_Id int
Declare @This_Element int
Declare @Adjacent_Element int
Select @This_Element = Element_Number, @This_PP_Setup_Id = PP_Setup_Id
  From Production_Setup_Detail 
  Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
-- Operations
-- 1 = Move Up
-- 2 = Move Down
-- We Are Moving Up Or Down  - Find Element Of Adjacent Item
If @Operation = 2 --Move Down
  Select @Adjacent_Element = max(Element_Number) From Production_Setup_Detail Where PP_Setup_Id = @This_PP_Setup_Id and Element_Number < @This_Element
Else              --Move Up
  Select @Adjacent_Element = min(Element_Number) From Production_Setup_Detail Where PP_Setup_Id = @This_PP_Setup_Id and Element_Number > @This_Element
-- Update The Implied Element
if @Adjacent_Element is Not Null
  Begin
    Update Production_Setup_Detail
      Set Element_Number = @This_Element 
      Where Element_Number = @Adjacent_Element
      And PP_Setup_Id = @This_PP_Setup_Id
    Update Production_Setup_Detail
      Set Element_Number = @Adjacent_Element 
      Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
  End
