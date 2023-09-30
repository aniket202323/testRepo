Create Procedure dbo.spGE_UpdateSetupDetail
@DetailId 	 int,
@Status 	  	 Int
 AS
Update Production_Setup_Detail Set Element_Status = @Status Where PP_Setup_Detail_Id = @DetailId
