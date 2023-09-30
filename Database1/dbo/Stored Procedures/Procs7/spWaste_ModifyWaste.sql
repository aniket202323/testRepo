
CREATE Procedure [dbo].[spWaste_ModifyWaste]
    @WED_Id           int        OUTPUT, 	 --  1: Input/Output -  Waste EventDetails Id
    @PU_Id            int, 	  	         --  2: Input  - MasterUnit Id
    @Source_PU_Id     int, 	  	         --  3: Input - UnitId [ it can be master or slave unit]
    @TimeStamp        Datetime, 	  	 --  4: Input - Time at which waste was generated
    @WET_Id           int, 	  	         --  5: Input - waste Event Type Id
    @WEMT_Id          int, 	  	         --  6: Input - Waste event measurement type id
    @Reason_Level1    int, 	  	         --  7: Input
    @Reason_Level2    int, 	  	         --  8: Input
    @Reason_Level3    int, 	  	         --  9: Input
    @Reason_Level4    int, 	  	         -- 10: Input
    @Action1 	  	  	 int,
    @Action2 	  	  	 int,
    @Action3 	  	  	 int,
    @Action4 	  	  	 int,
    @ActionCommentId 	 int,
    @Event_Id         int, 	  	         -- 11: Input  -- If it is a event based waste
    @Amount           float, 	  	  	  	 -- 12: Input  -- amount of the waste
    @WEFault_Id 	  	 int 	  	  	 = Null,   -- waste Fault Id
    @UserId 	  	  	 int,
    @CommentId 	  	 int,
    @Transaction_Type int
	
	AS

    DECLARE  @Event_Reason_Tree_Data_Id  Int = Null  -- NO need to pass this to core sproc, it is selecting Event_Reason_Tree_Data_Id based on the reasons provided
    DECLARE  @ECID 	  	  	  	 Int --  Need to check from where to populate this, for now pass this null to core sproc

   DECLARE  @ResearchCommentId int  	    -- Not being used currently
   DECLARE  @ResearchStatusId int  	         -- Not being used currently
   DECLARE @ResearchOpenDate datetime	  	   -- Not being used currently
   DECLARE @ResearchCloseDate datetime 	  	   -- Not being used currently
   DECLARE @ResearchUserId  int     	  	 -- Not being used currently
   DECLARE @Dimension_Y 	  	 Float      -- Not being used currently
   DECLARE @Dimension_Z 	  	 Float      -- Not being used currently
   DECLARE @Dimension_A 	  	 Float      -- Not being used currently
   DECLARE @Start_Coordinate_Z Float     -- Not being used currently
   DECLARE @Start_Coordinate_A Float     -- Not being used currently
   DECLARE @Dimension_X 	  	 Float    -- Not being used currently
   DECLARE @Start_Coordinate_X Float     -- Not being used currently
   DECLARE @Start_Coordinate_Y Float     -- Not being used currently
   DECLARE @Work_Order_Number nvarchar(50) -- Not being used currently
   DECLARE @User_General_1 	 nvarchar(255) -- Not being used currently
   DECLARE @User_General_2 	 nvarchar(255) -- Not being used currently
   DECLARE @User_General_3 	 nvarchar(255)  -- Not being used currently
   DECLARE @User_General_4 	 nvarchar(255) -- Not being used currently
   DECLARE @User_General_5 	 nvarchar(255) -- Not being used currently
   DECLARE @SignatureId 	  	 int



    /*
    TransactionType is 1 for add, 2 for update, 3 for delete
    */

DECLARE @TransNum INT = 4
DECLARE @ReturnResultSets INT = 2 -- This will put the data in pending resultset for rabbitMq so we don't have to
DECLARE @return_value int
DECLARE @CheckErrors INT,@InsertAccess bit, @DeleteAccess bit

    -- Verify the ids here before making the call to core sproc

	Select @InsertAccess = AddSecurity,@DeleteAccess = DeleteSecurity from dbo.fnWaste_GetWasteSecurity(ISNULL(@Source_PU_Id,@PU_Id),NULL,@UserId)

	IF @Transaction_Type in (1,2) And ISNULL(@InsertAccess,0) = 0
	Begin
	select @CheckErrors =1
    		SELECT Error = 'User does not have waste add permission, on any active configured sheets for the Unit','EWMS2090' as Code
	
	End
	
	--Uncomment after reverting change in Dao passing unit id
	/*
	 IF @Transaction_Type in (3) And ISNULL(@DeleteAccess,0) = 0
	Begin
	select @CheckErrors =1
		SELECT Error = 'User does not have waste delete permission, on any active configured sheets for the Unit','EWMS2091' as Code
	
	End
	*/

    if(@Transaction_Type in (1,2))   -- Common validations for add/update
        BEGIN
              IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @PU_Id) or @PU_Id is Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Master UnitId not exists','EWMS1001' as Code
			 	 END 
		  IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @Source_PU_Id) and @Source_PU_Id is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Source UnitId not exists','EWMS1002' as Code
			 	 END 	 
          IF NOT EXISTS(SELECT 1 FROM events WHERE event_id = @Event_Id) and @Event_Id is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Associated Production EventId not exists','EWMS1003' as Code
			 	 END 
          IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Reason_Level1) and @Reason_Level1 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Reason Level1 not exists','EWMS1004' as Code
			 	 END
		   IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Reason_Level2) and @Reason_Level2 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Reason Level2 not exists','EWMS1005' as Code
			 	 END
	       IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Reason_Level3) and @Reason_Level3 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Reason Level3 not exists','EWMS1006' as Code
			 	 END
		   IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Reason_Level4) and @Reason_Level4 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Reason Level4 not exists','EWMS1007' as Code
			 	 END	 	  		 	  	 	      
          IF NOT EXISTS(SELECT 1 FROM Waste_Event_Fault WHERE WEFault_Id = @WEFault_Id) and @WEFault_Id is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Waste Event FaultId not exists','EWMS1008' as Code
			 	 END 
		  IF NOT EXISTS(SELECT 1 FROM Waste_Event_Type WHERE WET_Id = @WET_Id) and @WET_Id is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Waste Event TypeId not exists','EWMS1009' as Code
			 	 END 	 
		   IF NOT EXISTS(SELECT 1 FROM Waste_Event_Meas WHERE WEMT_Id = @WEMT_Id) and @WEMT_Id is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Waste Measurement Id not exists','EWMS1010' as Code
			 	 END 	
		   IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Action1) and @Action1 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Action1 not exists','EWMS2025' as Code
			 	 END
		   IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Action2) and @Action2 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Action2 not exists','EWMS2026' as Code
			 	 END
	       IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Action3) and @Action3 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Action3 not exists','EWMS2027' as Code
			 	 END
		   IF NOT EXISTS(SELECT 1 FROM Event_Reasons WHERE Event_Reason_Id = @Action4) and @Action4 is not Null
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Action4 not exists','EWMS2028' as Code
			 	 END	 	 
	     SET @TimeStamp= dbo.fnServer_CmnConvertToDbTime(@TimeStamp,'UTC')    
        select   @ReturnResultSets = 2

        END

    if(@Transaction_Type = 1)   -- validations For Add
        BEGIN
	        
           select @ReturnResultSets = 2

        END

    if(@Transaction_Type = 2)  --  validations For Update
        BEGIN
        
          IF NOT EXISTS(SELECT 1 FROM Waste_Event_Details WHERE WED_Id = @WED_Id) 
			 	 BEGIN
				 select @CheckErrors =1
			 	  	 SELECT Error = 'Waste record not exists.','EWMS1000' as Code
			 	 END                   		 	   
          
          select @Event_Id = EVENT_ID from Waste_Event_Details where WED_Id =@WED_Id
          
          select @ActionCommentId = Action_Comment_Id  from Waste_Event_Details where WED_Id =@WED_Id
          
          select @CommentId = Cause_Comment_Id  from Waste_Event_Details where WED_Id =@WED_Id
          
        END

    if(@Transaction_Type = 3)  -- validations For Delete
        BEGIN

           select  @ReturnResultSets = 1
            select @TimeStamp = TimeStamp,@PU_Id = pu_id  from Waste_Event_Details where WED_Id =@WED_Id
            IF @TimeStamp IS NULL
               BEGIN
                      SELECT Error = 'Waste record not exists.','EWMS1000' as Code
               END           
        END

    IF @CheckErrors IS NULL
       BEGIN
	     
		    -- Now calling the core sproc for add/update/delete
		    EXEC	@return_value = [dbo].[spServer_DBMgrUpdWasteEvent]
		                            @WED_Id OUTPUT,
		                            @PU_Id,
		                            @Source_PU_Id,
		                            @TimeStamp,
		                            @WET_Id,
		                            @WEMT_Id,
		                            @Reason_Level1,
		                            @Reason_Level2,
		                            @Reason_Level3,
		                            @Reason_Level4,
		                            @Event_Id,
		                            @Amount,
		                            NULL, -- @Future1,
		                            NULL,  -- @Future2,
		                            @Transaction_Type,
		                            @TransNum,
		                            @UserId,
		                            @Action1,
		                            @Action2,
		                            @Action3,
		                            @Action4,
		                            @ActionCommentId,
		                            @ResearchCommentId,
		                            @ResearchStatusId,
		                            @CommentId,
		                            NULL,  -- @Future3 = 1,
		                            @ResearchOpenDate,
		                            @ResearchCloseDate,
		                            @ResearchUserId,
		                            @WEFault_Id,
		                            @Event_Reason_Tree_Data_Id, -- @Event_Reason_Tree_Data_Id, this will be set by core sproc itself
		                            @Dimension_Y,
		                            @Dimension_Z,
		                            @Dimension_A,
		                            @Start_Coordinate_Z,
		                            @Start_Coordinate_A,
		                            @Dimension_X,
		                            @Start_Coordinate_X,
		                            @Start_Coordinate_Y,
		                            @User_General_4,
		                            @User_General_5,
		                            @Work_Order_Number,
		                            @User_General_1,
		                            @User_General_2,
		                            @User_General_3,
		                            NULL, --  @ECID, currently passing null, need to check what to do with it
		                            @SignatureId,  --- @SignatureId, currently passing null, need to check what to do with it
		                            0
		      
		     	                             INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 Select  RSTId = 9, PreDB = 0, TransNum = @TransNum, UserId = @UserId, TransType = @Transaction_Type,
 	  	  	  	  	 WasteEventId = @WED_Id, PUId = @PU_Id, SourcePUId = @Source_PU_Id, TypeId = @WET_Id, MeasId = @WEMT_Id,
 	  	  	  	  	 Reason1 = @Reason_Level1, Reason2 = @Reason_Level2, Reason3 = @Reason_Level3, Reason4 = @Reason_Level4,
 	  	  	  	  	 EventId = @Event_Id, Amount = @Amount, Obsolete1 = Null, Obsolete2 = Null,
 	  	  	  	  	 TimeStampCol = @TimeStamp, Action1 = @Action1, Action2 = @Action2, Action3 = @Action3, Action4 = @Action4,
 	  	  	  	  	 ActionCommentId = @ActionCommentId, ResearchCommentId = @ResearchCommentId, ResearchStatusId = @ResearchStatusId,
 	  	  	  	  	 ResearchOpenDate = @ResearchOpenDate, ResearchCloseDate = @ResearchCloseDate, CommentId = @CommentId,
 	  	  	  	  	 Obsolete3 = Null, ResearchUserId = @ResearchUserId, FaultId = @WEFault_Id, RsnTreeDataId = @Event_Reason_Tree_Data_Id,
 	  	  	  	  	 DimensionX = @Dimension_X, DimensionY = @Dimension_Y, DimensionZ = @Dimension_Z, DimensionA = @Dimension_A,
 	  	  	  	  	 StartCoordinateX = @Start_Coordinate_X, StartCoordinateY = @Start_Coordinate_Y, StartCoordinateZ = @Start_Coordinate_Z,
 	  	  	  	  	 StartCoordinateA = @Start_Coordinate_A, General1 = @User_General_1, General2 = @User_General_2,
 	  	  	  	  	 General3 = @User_General_3, General4 = @User_General_4, General5 = @User_General_5, OrderNum = @Work_Order_Number,
 	  	  	  	  	 ECID = @ECId, ESigId = @SignatureId
 	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
	                       
		
		    Select
		                w.WED_Id WasteId,w.Amount WasteAmount,dbo.fnserver_CmnConvertFromDbTime(w.TimeStamp,'UTC') TimeStamp,dbo.fnserver_CmnConvertFromDbTime(w.Entry_On, 'UTC') EntryOn,w.Source_PU_Id SourceUnitId, w.PU_Id MasterUnitId,w.Event_Id AssociatedEventId,e.Event_Num AssociatedEventNum,w.WEFault_Id WasteEventFaultId,w.WET_Id WasteEventTypeId,w.WEMT_Id WasteMeasurementId,wem.Conversion AmountConversionDivisor, w.Cause_Comment_Id CauseCommentId,w.Action_Comment_Id ActionCommentId,w.Action_Level1 ActionLevel1Id,w.Action_Level2 ActionLevel2Id,w.Action_Level3 ActionLevel3Id,w.Action_Level4 ActionLevel4Id,w.Reason_Level1 ReasonLevel1Id,w.Reason_Level2 ReasonLevel2Id,w.Reason_Level3 ReasonLevel3Id,w.Reason_Level4 ReasonLevel4Id,w.User_Id UserId,ub.Username UserName,COALESCE(e.Applied_Product,ps.Prod_Id) AS ProductId ,null Confirmed,1 totalRecords 
		            from
		                Waste_Event_Details w
		                    LEFT JOIN Events e WITH (nolock) on e.Event_Id = w.Event_Id
		                    LEFT JOIN Waste_Event_Meas wem WITH (nolock) on wem.WEMT_Id = w.WEMT_Id
		                    LEFT JOIN Users_Base ub WITH (nolock) on ub.User_Id = w.User_Id
		                    LEFT JOIN Production_Starts ps on (ps.PU_Id = w.PU_Id AND ps.Start_Time <= w.TimeStamp  AND (ps.End_Time is NULL OR ps.End_Time >= w.TimeStamp) )
		            Where w.WED_Id =@WED_Id
	END	            

