--exec [spRS_GetOneEvent] 1,'India Standard Time'
CREATE PROCEDURE [dbo].[spRS_GetOneEvent]
@Event_Id int,
@InTimeZone varchar(200) =NULL
 AS
        Select EventId = e.Event_Id, 
 	  	 convert(varchar(20), e.Event_Num) + ' - ' + Convert(varchar(20), p.Prod_Code) + ' - ' + Convert(varchar(25),   [dbo].[fnServer_CmnConvertFromDbTime] (e.[timeStamp],@InTimeZone) ) 
 	  	 ,EventNumber = e.Event_Num
 	  	 ,'timeStamp'= [dbo].[fnServer_CmnConvertFromDbTime] (e.[timeStamp],@InTimeZone)  
 	  	 ,ProductCode = p.Prod_Code
          From Events e
          Join Production_Starts ps on ps.PU_Id = e.PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
          Join Products p on p.Prod_Id = ps.Prod_Id
 	   Where event_Id = @Event_Id
