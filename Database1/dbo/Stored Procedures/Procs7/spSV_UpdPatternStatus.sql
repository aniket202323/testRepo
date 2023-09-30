Create Procedure dbo.spSV_UpdPatternStatus
@PP_Setup_Detail_Id int,
@Element_Status tinyint
AS
  Update Production_Setup_Detail
    Set Element_Status = @Element_Status
    Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id 
