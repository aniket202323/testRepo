Create Procedure dbo.spWD_GetComments
@TEDetId int,
@SummaryDetId int = null
AS
 	 Select Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id,
 	  	    Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id
 	 From Timed_Event_Details D   WITH (NOLOCK)
 	 Where D.TEDet_Id = @TEDetId
IF @SummaryDetId is not null 
 	 Select Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id
 	 From Timed_Event_Details D   WITH (NOLOCK)
 	 Where D.TEDet_Id = @SummaryDetId
