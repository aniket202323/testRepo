Create Procedure dbo.spXLAGetGB_Rsum @Id integer, 
 	  	  	 @SearchTime datetime, 
 	  	  	 @which integer
 AS
  If @which = 1
    Select * from gb_rsum where pu_id = @Id and start_time = @SearchTime
  else
    Select * from gb_rsum where pu_id = @Id and end_time = @SearchTime
