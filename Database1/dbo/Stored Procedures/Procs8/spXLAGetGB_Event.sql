Create Procedure dbo.spXLAGetGB_Event  @Id integer, 
 	  	  	 @SearchTime datetime, 
 	  	  	 @which integer
 AS
  If @which = 1
    Select * from events where pu_id = @Id and timestamp < @SearchTime
  else
    Select * from events where pu_id = @Id and timestamp > @SearchTime
