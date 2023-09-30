














/*
---------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmsel_LineStatusComments2
Purpose: Provided line status schedule ID, selects the comments for line unit
	status schedule.
Date: 28-Jun-06			
By Vinayak Pate
---------------------------------------------------------------------------------------------------------------------------------------
Build #8 No Change
---------------------------------------------------------------------------------------------------------------------------------------
*/


CREATE     PROCEDURE spLocal_STLS_parmsel_LineStatusComments2
	--parameters
	@StatusScheduleID INT

AS

--DECLARE 

SELECT users.username, 
Convert(VARCHAR,Local_PG_Line_Status_Comments.Entered_On, 113)as Entry_On, 
Phrase.Phrase_Value, 
Left(Convert(VARCHAR,Local_PG_Line_Status_Comments.Start_DateTime, 113),17)as Start_DateTime, 
Left(Convert(VARCHAR,Local_PG_Line_Status_Comments.End_DateTime, 113),17)as End_DateTime, 
Local_PG_Line_Status_comments.comment_text

FROM Local_PG_Line_Status_comments
Inner Join Phrase ON Local_PG_Line_Status_comments.Line_Status_Id = Phrase.Phrase_Id
Inner Join Users ON Local_PG_Line_Status_comments.User_Id = users.user_Id
WHERE Local_PG_Line_Status_Comments.Status_Schedule_Id = @StatusScheduleID 

ORDER BY Local_PG_Line_Status_Comments.Comment_Id --Desc









