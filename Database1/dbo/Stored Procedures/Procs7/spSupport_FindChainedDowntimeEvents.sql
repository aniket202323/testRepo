CREATE PROCEDURE dbo.spSupport_FindChainedDowntimeEvents
@MaxNumChainedEvents int = NULL,
@MyPUID int = NULL
AS
If (@MaxNumChainedEvents is NOT NULL and @MyPUID is NOT NULL) or (@MaxNumChainedEvents is NULL and @MyPUID is NOT NULL)
 	 BEGIN
 	  	 If @MaxNumChainedEvents is NULL set @MaxNumChainedEvents = 50000
 	  	 Declare @@Lastst dateTime,@@pSt DateTime,@@pEt DateTime,@@Counter int,@@pu_id int,@@start_Time datetime
 	  	 select @@Counter = 0
 	  	 select @@pu_id = @MyPUID
 	  	 select @@start_Time = getdate()
 	  	 Select @@Lastst = max(Start_Time) from timed_Event_details where pu_Id = @@pu_id and start_Time < @@start_time
 	  	 nextet2:
 	  	 Select @@pSt = max(Start_Time) from timed_Event_details where pu_Id = @@pu_id and Start_Time < @@Lastst
 	  	 select @@pEt = end_Time from timed_Event_details where pu_Id = @@pu_id and Start_Time = @@pSt
 	  	 --select @@Lastst,@@pEt
 	  	 if @@pEt = @@Lastst and @@Counter < @MaxNumChainedEvents
 	  	  	 Begin 
 	  	  	 Select @@Counter = @@Counter + 1
 	  	  	 Select @@Lastst = @@pSt
 	  	  	 goto nextet2
 	  	  	 end
 	  	 select @@Counter as CountOfChainedEvents, @@PU_ID as PU_ID, @@Lastst as StartofDTMChain
 	 END
If (@MaxNumChainedEvents is NULL and @MyPUID is NULL) OR (@MaxNumChainedEvents is NOT NULL and @MyPUID is NULL)
 	 BEGIN
 	  	 If @MaxNumChainedEvents is NULL set @MaxNumChainedEvents = 5000
 	  	 --Step 1: Declare variables to hold the output from the cursor.
 	  	 Declare @PU_ID int, @PU_Desc Varchar(100), @Lastst dateTime, @pSt DateTime, @pEt DateTime, @Counter int, @start_Time datetime, @Comment Varchar(100)
 	  	 --Step 2: Declare the cursor object;
 	  	 DECLARE @ProdUnitsData as CURSOR;
 	  	 --Step 3: Assign the query to the cursor.
 	  	 SET @ProdUnitsData = CURSOR FOR
 	  	 Select PU_Id,PU_Desc From Prod_Units where Master_Unit is null and Pu_id <> 0
 	  	 --Step 4: Open the cursor.
 	  	 OPEN @ProdUnitsData;
 	  	 --Create TempTable
 	  	 Declare @AllMyChainedEvents Table(CountChainedEvents INT, PU_ID INT, PU_DESC Varchar(100), Comment varchar(100), StartOfDTMChain DateTime)
 	  	 ---Step 5: Fetch the first row.
 	  	 FETCH NEXT FROM @ProdUnitsData INTO @PU_ID, @PU_Desc
 	  	 WHILE @@FETCH_STATUS = 0
 	  	 BEGIN
 	  	  	  	 select @Counter = 0
 	  	  	  	 select @pu_id = @PU_ID
 	  	  	  	 select @start_Time = getdate()
 	  	  	  	 Select @Lastst = max(Start_Time) from timed_Event_details where pu_Id = @pu_id and start_Time < @start_time
 	  	  	 nextet:
 	  	  	  	 Select @pSt = max(Start_Time) from timed_Event_details where pu_Id = @pu_id and Start_Time < @Lastst
 	  	  	  	 select @pEt = end_Time from timed_Event_details where pu_Id = @pu_id and Start_Time = @pSt
 	  	  	 if @pEt = @Lastst and @Counter < @MaxNumChainedEvents
 	  	  	  	 Begin 
 	  	  	  	 Select @Counter = @Counter + 1
 	  	  	  	 Select @Lastst = @pSt
 	  	  	  	 goto nextet
 	  	  	  	 end
 	  	  	   
 	  	  	   Insert into @AllMyChainedEvents (CountChainedEvents,PU_ID,PU_DESC,Comment,StartOfDTMChain) values (@counter,@pu_id,@PU_desc,@Comment,@LastSt)
 	  	  	   Update @AllMyChainedEvents set Comment = '' where CountChainedEvents < 1000
 	  	  	   Update @AllMyChainedEvents set Comment = 'Performance Risk:  Max # of chained events > 1000 - Investigate DTM Chaining on Unit' where CountChainedEvents >= 1000
 	  	  FETCH NEXT FROM @ProdUnitsData INTO @PU_ID, @PU_Desc
 	  	 END
 	  	 --Step 6: Close the cursor.
 	  	 CLOSE @ProdUnitsData;
 	  	 ---Step 7: Deallocate the cursor to free up any memory or open result sets.
 	  	 DEALLOCATE @ProdUnitsData;
 	  	 Select * From @AllMyChainedEvents order by CountChainedEvents Desc
 	 END
