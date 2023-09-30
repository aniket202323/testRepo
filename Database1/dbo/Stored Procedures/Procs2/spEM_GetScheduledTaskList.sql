CREATE PROCEDURE dbo.spEM_GetScheduledTaskList
@EC_Id int
AS
Declare @Event_Type Int,@TableId Int
Select @Event_Type = ET_Id From Event_Configuration where ec_Id = @EC_Id
Select @TableId = case When @Event_Type = 1 then 1
 	  	  	  	    	    When @Event_Type = 2 then 3
 	  	  	  	    	    When @Event_Type = 3 then 4
 	  	  	  	    	    When @Event_Type = 4 then 2
 	  	  	  	    	    When @Event_Type = 14 then 11
 	  	  	  	  	    Else 0
 	  	  	  	   End
Select TaskId,TaskDesc From Tasks where TableId = @TableId
