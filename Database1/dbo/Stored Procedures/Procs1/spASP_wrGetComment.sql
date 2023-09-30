--exec [spASP_wrGetComment] 1,''
CREATE procedure [dbo].[spASP_wrGetComment]
@CommentId int,
@InTimeZone nvarchar(200)=NULL
AS
/*
 	 Fetches a comment and all of its chained child
 	 comments (where the requested comment is the top
 	 of the chain).  It is assumed that the comment
 	 at the top of the chain will always be the one attached
 	 to another object and so only comments at the top of the chain
 	 would be requested.  This is why this stored procedure
 	 does not go up the chain, only down.
*/
Select c.Comment_Id,'Entry_On'= [dbo].[fnServer_CmnConvertFromDbTime] (c.Entry_On,@InTimeZone), 'Modified_On'=[dbo].[fnServer_CmnConvertFromDbTime] (c.Modified_On,@InTimeZone), u.Username, c.Comment_Text
From Comments c
Join Users u On c.User_Id = u.User_Id
Where c.Comment_Id = @CommentId Or c.TopOfChain_Id = @CommentId
Order By c.Comment_Id
