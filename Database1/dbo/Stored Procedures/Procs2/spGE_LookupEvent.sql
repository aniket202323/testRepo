Create Procedure dbo.spGE_LookupEvent
  @Event_Num nvarchar(50)
  AS
   SELECT e.Event_Id,e.Event_Num,e.TimeStamp,p.PU_Desc,p.PU_Id
        FROM Events e
 	  	 Join Prod_Units p on p.PU_Id = e.PU_Id 
        WHERE Event_Num = @Event_Num
