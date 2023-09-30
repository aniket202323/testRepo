CREATE PROCEDURE dbo.spRS_SearchSingleEvent 
@PU_Id int,
@EventMask varchar(50),
@InTimeZone varchar(200)=NULL
AS
        Select EventId = e.Event_Id, 
 	  	 convert(varchar(20), e.Event_Num) + ' - ' + Convert(varchar(20), p.Prod_Code) + ' - ' + Convert(varchar(25),   dbo.fnServer_CmnConvertFromDBTime(e.timeStamp,@InTimeZone)  )
 	  	 ,EventNumber = e.Event_Num
 	  	 , 'TimeStamp'=dbo.fnServer_CmnConvertFromDBTime(e.TimeStamp,@InTimeZone)  
 	  	 ,ProductCode = p.Prod_Code
          From Events e
          Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
          Join Products p on p.Prod_Id = ps.Prod_Id
          Where e.PU_Id = @PU_Id 
                and upper(e.Event_Num) like '%' + Upper(@EventMask) + '%'
