
CREATE PROCEDURE [dbo].[spLocal_SA_CreateUDEWatchDog] 
----------------------------------------[Creation Of SP]-----------------------------------------  

  
/*  
Stored Procedure  :  spLocal_SA_CreateUDEWatchDog  
Author     :  Steven Stier (Stier Automation) 
Date Created   :  03/01/2023 
SP Type     :  Model 602  
Version     :  1.0.0  
Editor Tab Spacing :  2 
  
Description:  
=========  
SP used to create user_defined event for every 10 minutes For watchDog Event
  
  
CALLED BY:  Model 602 for Creation of user_define event 

Date					Version					Who								What  
===========		=======				=================		=========================================================================  
07/13/2023 		0.0.1				  Steven Stier				Creation of SP  

-------------------------------------------------------------------------------------------------------------------------------------------------

-- get all the debug messages
Select * from dbo.Local_SA_Debug where DebugSP = 'spLocal_SA_CreateUDEWatchDog'
and DebugInputs Like  '%@ECId=7690%' 
order by DebugId desc

delete local_SA_Debug

-- get all the sheets for a particular puis
Select sheet_id, Event_Subtype_Id,Master_unit, Sheet_desc from sheets where Master_unit = 650 -- prod unit = Stier watchdog unit
-- get all the user defined events for that sheet configuration
select UDE_ID,pu_id, user_id, UDE_DESC, Start_time, End_time, duration from User_Defined_Events 
where PU_ID =650 and Event_Subtype_Id = 123 order by start_time desc-- UDE -Stier WatchDog UDE

*/  
 
 --DECLARE
	@Status			int					OUTPUT,  
	@OutputMessage  varchar(255)		OUTPUT,  
	@ECId			int  

	AS 
	SET NOCOUNT ON
		DECLARE  
		--Standard information  
		@PuId			INT,  
		@UserId			INT,  
		@CurrentTime	DATETIME,  
		@EventSubTypeId	INT, 
		--last UDE info  
		@LastUDEStartTime	DATETIME,  
		--Next UDE info 
		@NextUDEStartTime	DATETIME, 
		@NextUDEEndTime	DATETIME, 
		@UDENum				VARCHAR(30)	,  
		@UDEId				INT			,  
		@UDEDuration		INT			,  
		@EventSubtypeDesc	VARCHAR(50),
		@UDEWatchDogFrequency INT

		SET @Status = 0  
		SET @OutputMessage = 'Unknown'  
		--------------------------------------------------------------------------------------------------------------
		-- Debugging variables - requires Local_SA_DEBUG table in DB 
		-------------------------------------------------------------------------------------------------------------
		DECLARE @DebugFlag int,
			@DebugSP [varchar](300),
			@DebugInputs [varchar](300),
			@DebugText [varchar](2000),
			@DebugTimestamp datetime
		-- Enable Debug here by setting = 1 - Dont leave this set. Local_SA_Debug gets too big
		SELECT @DebugFlag = 1

		SELECT @DebugTimestamp = GETDATE() 
		SELECT @DebugSP = 'spLocal_SA_CreateUDEWatchDog'
		SELECT @DebugInputs = '@ECId=' + Isnull(convert(nvarchar(10),@ECId),'Null')
		If @DebugFlag = 1 
			BEGIN 
				Select @DebugText = 'Starting :)'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END
		-- get the watchdogFreq from model config.
		EXEC spCmn_ModelParameterLookup @UDEWatchDogFrequency output , @ECId, 'WatchDogFreq(mins)', 0  
		If @DebugFlag = 1 
			BEGIN 
				Select @DebugText = '  @UDEWatchDogFrequency='+ Isnull(convert(nvarchar(10),@UDEWatchDogFrequency),'Null') + ' mins'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END

	 IF (@UDEWatchDogFrequency IS NULL or @UDEWatchDogFrequency = 0 )  
			BEGIN
				SET @Status = 0  
				SET @OutputMessage = 'WatchDogFrequency(mins) not found. @ECId=' + Isnull(convert(nvarchar(10),@ECId),'Null') 
				SET NOCOUNT OFF  
				RETURN
			END
	
 
		-- Get PU_Id and event_subtype  
		SELECT  @PuId = Pu_Id,  
			 @EventSubTypeId = Event_Subtype_Id  
		FROM  dbo.Event_Configuration WITH (NOLOCK)  
		WHERE  (Ec_Id = @ECId)  
  
		SET @CurrentTime = CONVERT(DATETIME,convert(varchar(25), getdate(), 120))
 
		--Get last event time  
		SET @LastUDEStartTime =  
		 (  
		 SELECT max(Start_Time)  
		 FROM  dbo.User_Defined_Events WITH (NOLOCK)  
		 WHERE  (Event_Subtype_Id = @EventSubTypeId)  
		 AND  (Pu_Id = @PuId) 
		 )  
		 If @DebugFlag = 1 
			BEGIN 
				Select @DebugText = '  @LastUDEStartTime='+  CONVERT(VARCHAR(30), @LastUDEStartTime, 120)
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END

		IF (@LastUDEStartTime IS NULL)  
			BEGIN
				set @NextUDEStartTime = @CurrentTime
			END
		ELSE
			BEGIN
				--determine when next UDE should occur
				SET @NextUDEStartTime = DATEADD(mi, @UDEWatchDogFrequency, @LastUDEStartTime)
			END

		If @DebugFlag = 1 
			BEGIN
				Select @DebugText = '  @NextUDEStartTime='+  CONVERT(VARCHAR(30), @NextUDEStartTime, 120) 
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			
				DECLARE @MinsTill varchar(30)
				SET @MinsTill = CONVERT(VARCHAR(30),CAST(DATEDIFF(ss, @CurrentTime, @NextUDEStartTime)/60.0 AS DECIMAL(5, 2)))
				Select @DebugText = ' Next Generated:' + @MinsTill + ' mins'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END

		IF (@NextUDEStartTime > @CurrentTime)
			BEGIN
					SET @Status = 1  
					SET @OutputMessage = 'NothingToDo'  
					If @DebugFlag = 1 
					BEGIN 
						Select @DebugText = 'Exiting: NothingToDo'
						Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
					END
					SET NOCOUNT OFF  
					RETURN
			END

		----------------------------------------------------------------------------------------------  
		--If we are here, it is because we need to create the UDE 
		----------------------------------------------------------------------------------------------  
		SET @EventSubtypeDesc =   
		 (  
		 SELECT Event_Subtype_Desc   
		 FROM dbo.Event_Subtypes WITH (NOLOCK)   
		 WHERE (Event_Subtype_Id = @EventSubTypeId)  
		 )  

		SET @UserId = coalesce(  
		 (  
		 SELECT [User_Id]   
		 FROM dbo.Users WITH (NOLOCK)   
		 WHERE (UserName = 'WATCHDog')  
		 ), 6)  

		SET @NextUDEStartTime = CONVERT(DATETIME,convert(varchar(25), @NextUDEStartTime, 120))

		SET @UDENum = CONVERT(VARCHAR(30), @NextUDEStartTime, 20) + '-WATCHDog' 
		SET @NextUDEEndTime = dateadd(ss, 1, @NextUDEStartTime)  
		SET @UDEDuration = 1  
  
		If @DebugFlag = 1 
			BEGIN 
				Select @DebugText = '  Creating UDE: '+  @UDENum
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END

			 -- create the event on the unit for the path  
		EXEC dbo.spServer_DBMgrUpdUserEvent
			 2,          -- *Transaction Number  0=Update fields that are not null 2=Update all fields  
			 @EventSubtypeDesc,    -- *Event Subtype Desc  
			 NULL,         -- Action Comment Id  
			 NULL,         -- Action 4  
			 NULL,         -- Action 3  
			 NULL,         -- Action 2  
			 NULL,         -- Action 1  
			 NULL,         -- Cause Comment Id  
			 NULL,         -- Cause 4  
			 NULL,         -- Cause 3  
			 NULL,         -- Cause 2  
			 NULL,         -- Cause 1  
			 @UserId,        -- Ack By  
			 1,          -- *Ack  
			 @UDEDuration,      -- Duration  
			 @EventSubtypeId,     -- *Event Subtype Id  
			 @PUId,        -- *Pu Id  
			 @UDENum,        -- *Ude Desc  
			 @UDEId OUTPUT,      -- *Ude Id  
			 @UserId,        -- *User Id  
			 NULL, -- @CurrentTime,      -- Ack On  
			 @NextUDEStartTime,      -- *Start Time  
			 @NextUDEEndTime,      -- *End Time  
			 NULL,         -- Research Comment Id  
			 NULL,         -- Research Status Id  
			 NULL,         -- Research User Id  
			 NULL,         -- Research Open Date  
			 NULL,         -- Research Close Date  
			 1,          -- *Transtype  
			 NULL,         -- UDE Comment Id  
			 NULL,         -- Event Reason Tree Data Id   
			 NULL,		-- SignatureId
			NULL,		-- EventId
			NULL,			-- ParentUDEId
			NULL,			-- Event_Status
			NULL,			-- TestingStatus
			NULL,			-- Conformance
			NULL,			-- TestPctComplete
	1			--@ReturnResultSet 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table 

		-- post UDE to displays  
		SELECT 8,       -- UDE Resultset  
			 0,       -- Pre=1 Post=0  
			 NULL,      -- User Defined Event Id  
			 @UDENum,     -- User_Defined_Events Desc  
			 @PUId,     -- Unit Id  
			 @EventSubtypeId,  -- Event Subtype Id  
			 @NextUDEStartTime,   -- Start Time  
			 @NextUDEEndTime,    -- End Time  
			 @UDEDuration,   -- Duration  
			 1,       -- Acknowledged  
			 NULL, -- @CurrentTime,   -- Ack Timestamp  
			 @UserId,     -- Acknowledged By  
			 NULL,      -- Cause 1  
			 NULL,      -- Cause 2  
			 NULL,      -- Cause 3  
			 NULL,      -- Cause 4  
			 NULL,      -- Cause Comment Id  
			 NULL,      -- Action 1  
			 NULL,      -- Action 2  
			 NULL,      -- Action 3  
			 NULL,      -- Action 4  
			 NULL,      -- Action Comment Id  
			 NULL,      -- Research User Id  
			 NULL,      -- Research Status Id  
			 NULL,      -- Research Open Date  
			 NULL,      -- Research Close Date  
			 NULL,      -- Research Comment Id  
			 NULL,      -- Comments (Comment_Id)  
			 1,       -- Transaction Type  1=Add 2=Update 3=Delete  
			 @EventSubtypeDesc, -- Event Sub Type Desc  
			 2,       -- Transaction Number  0=Update fields that are not null 2=Update all fields  
			 @UserId,     -- User Id  
			NULL,		--ESigId
			NULL,		--ProductionEventId
			NULL,		--ParentUDEId
			NULL,		--EventStatus
			NULL,		--TestingStatus
			NULL		--TestPctComplete 


		SET @Status = 1  
		SET @OutputMessage = ''  
 
	 If @DebugFlag = 1 
			BEGIN 
				Select @DebugText = 'Complete'
				Insert into dbo.Local_SA_Debug (DebugTimestamp,DebugSP,DebugInputs,DebugText) Values(@DebugTimestamp,@DebugSP,@DebugInputs,@DebugText)
			END
	SET NOCOUNT OFF  

