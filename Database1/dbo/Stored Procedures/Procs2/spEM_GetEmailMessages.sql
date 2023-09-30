CREATE PROCEDURE dbo.spEM_GetEmailMessages
 	 @SearchString 	  	 nVarChar(100),
 	 @SearchField 	  	 Int,
 	 @SearchType 	  	 Int
AS
Declare @likeClause nVarChar(300)
If @SearchString Is Null
 	 Begin
 	  	 Select EG_Id = Isnull(EG_Id,-1),Message_id,Message_Subject,Message_Text,Severity = isnull(Severity,0) from Email_Message_Data order by Message_id
 	 End
Else
  BEGIN
 	   If @SearchType = 1
 	    	 Select @likeClause =  @SearchString + '%'
 	   If @SearchType = 2
 	    	 Select @likeClause = '%' + @SearchString + '%'
 	   If @SearchType = 3
 	    	 Select @likeClause = '%' + @SearchString
 	   If @SearchField = 1 --Subject
 	     Begin
 	  	  	 Select  EG_Id = Isnull(EG_Id,-1),Message_id,Message_Subject,Message_Text,Severity = isnull(Severity,0) from Email_Message_Data Where Message_Subject like @likeClause  order by Message_id
 	     End
 	   Else
 	     Begin  -- message
 	  	  	 Select  EG_Id = Isnull(EG_Id,-1),Message_id,Message_Subject,Message_Text,Severity = isnull(Severity,0) from Email_Message_Data Where Message_text like @likeClause  order by Message_id
 	     End
  END
