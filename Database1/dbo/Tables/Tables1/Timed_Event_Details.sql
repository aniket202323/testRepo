CREATE TABLE [dbo].[Timed_Event_Details] (
    [TEDet_Id]                    INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Action_Comment_Id]           INT          NULL,
    [Action_Level1]               INT          NULL,
    [Action_Level2]               INT          NULL,
    [Action_Level3]               INT          NULL,
    [Action_Level4]               INT          NULL,
    [Amount]                      FLOAT (53)   NULL,
    [Cause_Comment_Id]            INT          NULL,
    [End_Time]                    DATETIME     NULL,
    [Event_Reason_Tree_Data_Id]   INT          NULL,
    [Initial_User_Id]             INT          NULL,
    [PU_Id]                       INT          NOT NULL,
    [Reason_Level1]               INT          NULL,
    [Reason_Level2]               INT          NULL,
    [Reason_Level3]               INT          NULL,
    [Reason_Level4]               INT          NULL,
    [Research_Close_Date]         DATETIME     NULL,
    [Research_Comment_Id]         INT          NULL,
    [Research_Open_Date]          DATETIME     NULL,
    [Research_Status_Id]          INT          NULL,
    [Research_User_Id]            INT          NULL,
    [Signature_Id]                INT          NULL,
    [Source_PU_Id]                INT          NULL,
    [Start_Time]                  DATETIME     NOT NULL,
    [Summary_Action_Comment_Id]   INT          NULL,
    [Summary_Cause_Comment_Id]    INT          NULL,
    [Summary_Research_Comment_Id] INT          NULL,
    [TEFault_Id]                  INT          NULL,
    [TEStatus_Id]                 INT          NULL,
    [Uptime]                      FLOAT (53)   NULL,
    [User_Id]                     INT          NULL,
    [Work_Order_Number]           VARCHAR (50) NULL,
    [Duration]                    AS           (CONVERT([decimal](10,2),datediff(second,[Start_Time],[End_Time])/(60.0),0)),
    CONSTRAINT [TEvent_Details_PK_TEDetId] PRIMARY KEY NONCLUSTERED ([TEDet_Id] ASC),
    CONSTRAINT [TEvent_Details_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [TEvent_Details_FK_RsnLevel1] FOREIGN KEY ([Reason_Level1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Details_FK_RsnLevel2] FOREIGN KEY ([Reason_Level2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Details_FK_RsnLevel3] FOREIGN KEY ([Reason_Level3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Details_FK_RsnLevel4] FOREIGN KEY ([Reason_Level4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [TEvent_Details_FK_RUserId] FOREIGN KEY ([Research_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [TEvent_Details_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [TEvent_Details_FK_SrcPUId] FOREIGN KEY ([Source_PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [TEvent_Details_FK_TEFaultId] FOREIGN KEY ([TEFault_Id]) REFERENCES [dbo].[Timed_Event_Fault] ([TEFault_Id]),
    CONSTRAINT [TEvent_Details_FK_TEStatusId] FOREIGN KEY ([TEStatus_Id]) REFERENCES [dbo].[Timed_Event_Status] ([TEStatus_Id]),
    CONSTRAINT [TEvent_Details_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE CLUSTERED INDEX [TEvent_Details_IDX_PUIdSTime]
    ON [dbo].[Timed_Event_Details]([PU_Id] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [TEvent_Details_IDX_PUIdETime]
    ON [dbo].[Timed_Event_Details]([PU_Id] ASC, [End_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [TEvent_Details_IDX_TEFault_Id]
    ON [dbo].[Timed_Event_Details]([TEFault_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_Timed_Event_Details_PU_Id_Event_Reason_Tree_Data_Id_End_Time_Start_Time]
    ON [dbo].[Timed_Event_Details]([PU_Id] ASC, [Event_Reason_Tree_Data_Id] ASC, [End_Time] ASC, [Start_Time] ASC);


GO
 
/*
 
 --2016-03-21	Version 1.0							Initial Version 
 --2016-04-05	Version 1.1							Cover test case 4, still with defect because does not address the correct end time (change backed out) 
 --2016-04-05	Version 1.2							Cover test case 4, if downtime is already ended, insert an NPT record 
 --2016-04-05	Version 1.3							Cover test case 6, New test case related to durration 
 --2016-04-07	Version 1.4							Cover test case 7, new case  
 --2016-04-14	Version 1.5							1. If there is no Crew Schedule then make Next Monday the Start of the Production Day 
	--												2. If the last one that Updated the NPT Table was not Comxclient then do not change the End Time of the NPT 
 --2016-12-20	Version 1.6							FO-02742 Change to create NPT with end time 21 days in future instead of Next Monday for an Open downtime
 --2018-09-12	Version 2.4							updated for the correct category
 --2018-09-24	Version 2.5		Martin Casalis		FO-03585: NPT change to populate all units of active production plan
 --2021-10-26	Version 2.6		Martin Casalis		FO-04868: LEDS Automation - NPT Calendar - PR Out Line not staffed default - Grooming GBU
	--												Remove PO Active condition
 --2022-09-21	Version 2.7		Martin Casalis		FO-05248: STNU -Fill to Buffer- Grooming
 -- 2023-03-21	Version 2.8		Martin Casalis		Added logic to create an STNU NPT when category is curtailment (PARTS Non-Run)
*/
 
CREATE TRIGGER [dbo].[Local_TimedEventDetails_UpdateNPT] 
  ON [dbo].[Timed_Event_Details] 
  AFTER UPDATE 
  AS 
        
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge 
DECLARE
		 @Start					INT 
		,@End					INT 
		,@MyPUId				INT
		,@TEDetId				INT
		,@MyStartTime			DATETIME
		,@MyEndTime				DATETIME 
		,@RL1					INT
		,@MyUserId				INT 
		,@Now					DATETIME 
		,@OldStartTime			DATETIME 
		,@MyNPDetId				INT 
		,@PUID					INT                    --this is the pu_id in question
		,@ActivePath			INT                           --this is the path_id from dbo.production_plan where hte order is active for the unit in question
		,@EODHour				NVARCHAR(2) 
 		,@EODMin				NVARCHAR(2)
 		,@EODHourParId			INT
 		,@EODMinParId			INT
 		,@STODTime				NVARCHAR(6)
 		,@After21Days			DATE
		,@idx					INT
		,@idxMax				INT
		,@NPTGroupId			INT
		,@PROutSTNUId			INT

DECLARE @Units	TABLE
		(Id						INT IDENTITY(1,1)
		,PUId					INT)

DECLARE @Paths	TABLE
		(Id						INT IDENTITY(1,1)
		,PathId					INT)
 --  

DECLARE @UpdatedData TABLE 
		(Id						INT IDENTITY(1,1) 
 		,TEDetId				INT  NULL 
		,EventReasonTreeDataId	INT  NULL
 		,PUId					INT  NULL 
 		,StartTime				DATETIME NULL 
 		,EndTime				DATETIME NULL
 		,ReasonLevel1			INT NULL 
 		,ReasonLevel2			INT NULL 
 		,ReasonLevel3			INT NULL 
 		,ReasonLevel4			INT NULL 
 		,UserId					INT NULL
 		,NPTGroupId				INT NULL
		,ERCDesc				NVARCHAR(100)) 
 
SELECT @Now = dbo.fnServer_CmnConvertToDbTime(getutcdate(),'UTC') 
 
INSERT INTO @UpdatedData
		(TEDetId
		,EventReasonTreeDataId
 		,PUId
 		,StartTime
 		,EndTime
 		,ReasonLevel1
 		,ReasonLevel2
 		,ReasonLevel3
 		,ReasonLevel4
 		,UserId
		,ERCDesc) 
SELECT  
		 i.TEDet_Id
		,i.Event_Reason_Tree_Data_Id
 		,i.PU_Id
		,i.Start_Time
		,i.End_Time
		,i.Reason_Level1
		,i.Reason_Level2
		,i.Reason_Level3
		,i.Reason_Level4
		,i.User_Id   
		,erc.ERC_Desc
--FROM UPDATED u 
FROM INSERTED i 
JOIN dbo.Event_Reasons						er		WITH(NOLOCK)	ON i.Reason_Level1 = er.Event_Reason_Id 
JOIN dbo.Event_Reason_Category_Data			ercd	WITH(NOLOCK)	ON ercd.Event_Reason_Tree_Data_Id = i.Event_Reason_Tree_Data_Id
JOIN dbo.Event_Reason_Catagories			erc		WITH(NOLOCK)	ON erc.ERC_Id = ercd.ERC_Id
WHERE erc.ERC_Desc LIKE 'Non-Productive Time'
	OR	erc.ERC_Desc LIKE 'PARTS Non-Run:%'	

-- Return if there is not data to add 
IF NOT EXISTS (SELECT * FROM @UpdatedData) 
BEGIN 
		RETURN 
END 


SELECT @NPTGroupId = [NPT_Group_Id]
FROM [dbo].[NPT_Detail_Grouping] WITH(NOLOCK) 
WHERE [NPT_Group_Desc] LIKE 'Group Meetings'

UPDATE udata
	SET NPTGroupId = CASE WHEN erc.ERC_Desc LIKE 'Buffer Full' THEN @NPTGroupId ELSE NULL END
FROM @UpdatedData							udata
JOIN dbo.Timed_Event_Details				ted		WITH(NOLOCK)	ON udata.TEDetId = ted.TEDet_Id
JOIN dbo.Event_Reason_Category_Data			ercd	WITH(NOLOCK)	ON ercd.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id
JOIN dbo.Event_Reason_Catagories			erc		WITH(NOLOCK)	ON erc.ERC_Id = ercd.ERC_Id
WHERE erc.ERC_Desc LIKE 'Buffer Full'


-- Get Event_Reason_Id for NPT / PR Out: STNU
IF EXISTS(SELECT * FROM @UpdatedData WHERE ERCDesc LIKE 'PARTS Non-Run:%')
BEGIN
	SELECT  @PROutSTNUId = er.Event_Reason_Id 
		FROM dbo.Event_Reasons					er		WITH(NOLOCK)
		JOIN dbo.Event_Reason_Tree_Data			ertd	WITH(NOLOCK)	ON er.Event_Reason_Id = ertd.Event_Reason_Id
		JOIN dbo.Event_Reason_Tree				ert		WITH(NOLOCK)	ON ert.Tree_Name_Id = ertd.Tree_Name_Id
		JOIN dbo.Event_Reason_Category_Data		ercd	WITH(NOLOCK)	ON ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
		JOIN dbo.Event_Reason_Catagories		erc		WITH(NOLOCK)	ON ercd.ERC_ID = erc.ERC_ID
		WHERE ert.Tree_Name = 'Non-Productive Time'
		AND erc.ERC_Desc = 'validNPTAdmin'
		AND er.Event_Reason_Name_Global LIKE 'PR Out: STNU'

	IF @PROutSTNUId IS NULL
	BEGIN 
			RETURN 
	END 
END

	
-- Get the Path from the units    
INSERT INTO @Paths (PathId)
SELECT DISTINCT pp.Path_Id
FROM dbo.Production_Plan					pp		WITH(NOLOCK) 
JOIN dbo.PrdExec_Path_Units					ppu		WITH(NOLOCK)	ON ppu.Path_Id = pp.Path_Id
JOIN dbo.Production_Plan_Statuses			pps		WITH(NOLOCK)	ON pps.PP_Status_Id = pp.PP_Status_Id
JOIN @UpdatedData							ud						ON ppu.PU_Id = ud.PUId
--WHERE pps.PP_Status_Desc = 'Active'
	   
-- Get all the Units from Execution Path
---------------------------------------------------------------------------------------------------
INSERT INTO  @Units (PUId)
SELECT DISTINCT pu.PU_Id 
FROM dbo.PrdExec_Path_Units		ppu WITH(NOLOCK) 
JOIN dbo.Prod_Units_Base		pu	WITH(NOLOCK) ON pu.PU_Id = ppu.PU_Id
WHERE ppu.Path_Id IN (SELECT PathId FROM @Paths)
	AND pu.Non_Productive_Reason_TREE IS NOT NULL


--INSERT INTO dbo.Local_Debug (Timestamp,CallingSP, Message) 
--VALUES (GETDATE(),'Local_TimedEventDetails_UpdateNPT','Firing') 

-- Get the start of the day from the Site Parameters table in case there is no Crew Schedule 
SELECT @EODHourParId = Parm_Id 
FROM dbo.Parameters WITH(NOLOCK) 
WHERE Parm_Name LIKE '%EndOfDayHour%' 

SELECT @EODMinParId = Parm_Id 
FROM dbo.Parameters WITH(NOLOCK) 
WHERE Parm_Name LIKE '%EndOfDayMinute%' 


SELECT @EODHour = ISNULL(Value,'00') 
FROM dbo.Site_Parameters WITH(NOLOCK) 
WHERE Parm_id = @EODHourParId 

SELECT @EODMin = ISNULL(Value,'00') 
FROM dbo.Site_Parameters WITH(NOLOCK) 
WHERE Parm_id = @EODMinParId 


SET @STODTime = @EODHour + ':' + @EODMin 
  
    --INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message) 
    --VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','Before While Loop >>' + @STODTime) 
 
 
SET @Start = 1 
SELECT @End = COUNT(*) FROM @UpdatedData 
WHILE  @Start <= @End 
BEGIN 
		SET @idx = 1
		SELECT @idxMax = COUNT(*) FROM @Units

		WHILE @idx <= @idxMax
		BEGIN
	
			SELECT @MyPUId = PUId
			FROM @Units
			WHERE Id = @idx
 
 			SELECT	 @MyStartTime = StartTime
					,@MyEndTime = EndTime 
 					,@RL1 = CASE WHEN ERCDesc LIKE 'PARTS Non-Run:%' THEN @PROutSTNUId ELSE ReasonLevel1 END
					,@MyUserId = UserId  
					,@NPTGroupId = NPTGroupId
					,@TEDetId = TEDetId
			FROM @UpdatedData  
			WHERE Id = @Start 
 
 		  -- This code assumes that Start_Time will never be modified. 
			SELECT @OldStartTime = Start_Time 
				   FROM DELETED 
				   WHERE TEDet_Id = @TEDetId 
 
 
 			IF @MyEndTime IS NOT NULL 
			BEGIN 
				 -- The Stop Closes, look for the associated NPT: 
 				SELECT @MyNPDetId = NPDet_Id  
				FROM dbo.NonProductive_Detail WITH(NOLOCK)
				WHERE PU_Id = @MyPUId 
					AND Start_Time = @OldStartTime 


                
 				--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message) 
 				--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','1st IF @MyNPDetId IS NOT NULL') 
 				-- Update the NPT with the New End_Time 
 				IF @MyNPDetId IS NOT NULL 
				BEGIN 
 					IF EXISTS (SELECT * FROM  
 								dbo.NonProductive_Detail WITH(NOLOCK) 
								WHERE NPDet_Id = @MyNPDetId 
								--AND User_id = 1						-- Removed for FO-05248. User can be different than comxclient after downtime update
								)  								
 					BEGIN 
 							--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message) 
 							--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','1st IF @MyNPDetId IS NOT NULL Trying to MOdify') 
 							BEGIN TRY 
 									EXEC dbo.spServer_DBMgrUpdNonProductiveTime
 												 @NPDetId = @MyNPDetId 
 												,@PUId = @MyPUId 
 												,@StartTime = @MyStartTime 
 												,@EndTime = @MyEndTime 
 												,@ReasonLevel1 = @RL1 
 												,@ReasonLevel2 = Null 
 												,@ReasonLevel3 = Null 
 												,@ReasonLevel4 = Null 
 												,@TransactionType = 2 
 												,@TransNum = 0 
 												,@UserId = @MyUserId 
 												,@CommentId = 0 
 												,@ERTDataId = Null 
 												,@EntryOn = @Now 
												,@NPTGroupId = @NPTGroupId
 												,@ReturnAllResults =  1 
 							END TRY 
 							BEGIN CATCH 
 							END CATCH 
 					END 
				END  
 				ELSE 
 				BEGIN 
 					--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message) 
 					--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','1st ELSE @MyNPDetId IS NOT NULL') 
 					BEGIN TRY 
 							EXEC dbo.spServer_DBMgrUpdNonProductiveTime
 										 @NPDetId = Null 
 										,@PUId = @MyPUId 
 										,@StartTime = @MyStartTime 
 										,@EndTime = @MyEndTime 
 										,@ReasonLevel1 = @RL1 
 										,@ReasonLevel2 = Null 
 										,@ReasonLevel3 = Null 
 										,@ReasonLevel4 = Null 
 										,@TransactionType = 1 
 										,@TransNum = 0 
 										,@UserId = 1 -- @MyUserId 
 										,@CommentId = 0 
 										,@ERTDataId = Null 
 										,@EntryOn = @Now 
										,@NPTGroupId = @NPTGroupId
 										,@ReturnAllResults =  1 
 

 					END TRY 
 					BEGIN CATCH 
 					END CATCH 
 				END 
 			     
			END 
			ELSE 
 			BEGIN	 
 				--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message) 
 				--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','2ND ELSE @MyNPDetId IS NULL') 
 				--	BEGIN TRY 
				SET @MyEndTime = 	dateadd(day,21,@MyStartTime)   --FO-02742
	-- 	Commented for FO-02742			
	--				SET @MyEndTime = 	 
	-- 					(CASE 	WHEN DATENAME(dw,dateadd(day,1,@MyStartTime))='Monday' THEN dateadd(day,1,@MyStartTime) 
	-- 							WHEN datename(dw,dateadd(day,2,@MyStartTime))='Monday' THEN dateadd(day,2,@MyStartTime) 
	-- 							WHEN datename(dw,dateadd(day,3,@MyStartTime))='Monday' THEN dateadd(day,3,@MyStartTime) 
	-- 							WHEN datename(dw,dateadd(day,4,@MyStartTime))='Monday' THEN dateadd(day,4,@MyStartTime) 
	-- 							WHEN datename(dw,dateadd(day,5,@MyStartTime))='Monday' THEN dateadd(day,5,@MyStartTime) 
	-- 							WHEN datename(dw,dateadd(day,6,@MyStartTime))='Monday' THEN dateadd(day,6,@MyStartTime) 
	-- 							WHEN datename(dw,dateadd(day,7,@MyStartTime))='Monday' THEN dateadd(day,7,@MyStartTime) 
	-- 					END) --DATEADD(DAY,7,@MyStartTime)	SET @MyEndTime = DATEADD(DAY,7,@MyStartTime) 
 	 
				IF EXISTS (SELECT * FROM dbo.Crew_Schedule WITH(NOLOCK) 
							WHERE PU_Id = @MyPUId 
							AND CONVERT(DATE,@MyEndTime) BETWEEN Start_Time AND End_Time) 
				BEGIN 
					SET @MyEndTime = (SELECT TOP 1 End_Time 
										FROM dbo.Crew_Schedule WITH(NOLOCK) 
										WHERE PU_Id = @MyPUId 
										AND CONVERT(DATE,@MyEndTime) BETWEEN Start_Time AND End_Time) 
				END 
				ELSE 
				BEGIN 
					-- Make next Monday the Start of the Production Day 
					SET	@After21Days = @MyEndTime 
					SELECT @MyEndTime = CONVERT(DATETIME,CONVERT(NVARCHAR,@After21Days) + ' ' + @STODTime) 
				END 
				
				IF EXISTS (SELECT * 
							FROM dbo.NonProductive_Detail WITH(NOLOCK) 
							WHERE pu_id = @MyPUId 
							AND Start_time > @MyStartTime  
							AND Start_time < @MyEndTime )
				BEGIN 
					SET @MyEndTime = (SELECT TOP 1 Start_time 
										FROM dbo.NonProductive_Detail WITH(NOLOCK) 
										WHERE PU_Id = @MyPUId 
										AND Start_time > @MyStartTime 
										AND Start_time < @MyEndTime  
										ORDER BY Start_Time ASC)
				END
				
				
				-- 
				BEGIN TRY 
						EXEC dbo.spServer_DBMgrUpdNonProductiveTime
								 @NPDetId = Null 
								,@PUId = @MyPUId 
								,@StartTime = @MyStartTime 
								,@EndTime = @MyEndTime 
								,@ReasonLevel1 = @RL1 
								,@ReasonLevel2 = Null 
								,@ReasonLevel3 = Null 
								,@ReasonLevel4 = Null 
								,@TransactionType = 1 
								,@TransNum = 0 
								,@UserId = 1 --@MyUserId 
								,@CommentId = 0 
								,@ERTDataId = Null 
								,@EntryOn = @Now 
								,@NPTGroupId = @NPTGroupId
								,@ReturnAllResults =  1 
				END TRY 
				BEGIN CATCH 
				END CATCH 
 			END 

			SET @idx = @idx + 1
		END
        SET @Start = @Start + 1 
END 


GO
DISABLE TRIGGER [dbo].[Local_TimedEventDetails_UpdateNPT]
    ON [dbo].[Timed_Event_Details];


GO
CREATE TRIGGER [dbo].[Timed_Event_Details_History_Upd]
 ON  [dbo].[Timed_Event_Details]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 400
 If (@Populate_History = 1) and ( Update(Action_Comment_Id) or Update(Action_Level1) or Update(Action_Level2) or Update(Action_Level3) or Update(Action_Level4) or Update(Amount) or Update(Cause_Comment_Id) or Update(End_Time) or Update(Event_Reason_Tree_Data_Id) or Update(Initial_User_Id) or Update(PU_Id) or Update(Reason_Level1) or Update(Reason_Level2) or Update(Reason_Level3) or Update(Reason_Level4) or Update(Research_Close_Date) or Update(Research_Comment_Id) or Update(Research_Open_Date) or Update(Research_Status_Id) or Update(Research_User_Id) or Update(Signature_Id) or Update(Source_PU_Id) or Update(Start_Time) or Update(Summary_Action_Comment_Id) or Update(Summary_Cause_Comment_Id) or Update(Summary_Research_Comment_Id) or Update(TEDet_Id) or Update(TEFault_Id) or Update(TEStatus_Id) or Update(Uptime) or Update(User_Id) or Update(Work_Order_Number)) 
   Begin
 	  	   Insert Into Timed_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,End_Time,Event_Reason_Tree_Data_Id,Initial_User_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Time,Summary_Action_Comment_Id,Summary_Cause_Comment_Id,Summary_Research_Comment_Id,TEDet_Id,TEFault_Id,TEStatus_Id,Uptime,User_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.End_Time,a.Event_Reason_Tree_Data_Id,a.Initial_User_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Time,a.Summary_Action_Comment_Id,a.Summary_Cause_Comment_Id,a.Summary_Research_Comment_Id,a.TEDet_Id,a.TEFault_Id,a.TEStatus_Id,a.Uptime,a.User_Id,a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Timed_Event_Details_Del 
  ON dbo.Timed_Event_Details 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
  @This_Time datetime,
  @This_Unit int,
  @This_Id int,
  @NextId int,
  @NextTime datetime
/* Comments deleted in Dbmgr sp*/
--
  DECLARE Timed_Event_Details_Del_Cursor CURSOR
    FOR SELECT TEDET_Id, PU_Id, Start_Time
       FROM DELETED
    FOR READ ONLY
  OPEN Timed_Event_Details_Del_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Timed_Event_Details_Del_Cursor INTO @This_Id, @This_Unit, @This_Time
  IF @@FETCH_STATUS = 0
    BEGIN
 	  	 Execute spServer_CmnRemoveScheduledTask @This_Id,3
 	  	 Select @NextId = NULL
 	  	 Select @NextId = TEDET_Id,@NextTime = Start_Time 
 	  	  	 from Timed_Event_Details
 	  	  	 where (pu_id = @This_Unit) and (Start_Time = (select min(Start_Time) from Timed_Event_Details where pu_id = @This_Unit and Start_Time > @This_Time))  and
 	  	  	 (TEDET_Id NOT IN (SELECT TEDET_Id FROM DELETED))
      If (@NextId Is Not NULL)
     	   Execute spServer_CmnAddScheduledTask @NextId,3,@This_Unit,@NextTime
      GOTO Fetch_Next_Event
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error in Timed_Event_Detail_Del (@@FETCH_STATUS = %d).', 11,
        -1, @@FETCH_STATUS)
    END
  DEALLOCATE Timed_Event_Details_Del_Cursor

GO
CREATE TRIGGER [dbo].[Timed_Event_Details_History_Ins]
 ON  [dbo].[Timed_Event_Details]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 400
 If (@Populate_History = 1 or @Populate_History = 3)  and ( Update(Action_Comment_Id) or Update(Action_Level1) or Update(Action_Level2) or Update(Action_Level3) or Update(Action_Level4) or Update(Amount) or Update(Cause_Comment_Id) or Update(End_Time) or Update(Event_Reason_Tree_Data_Id) or Update(Initial_User_Id) or Update(PU_Id) or Update(Reason_Level1) or Update(Reason_Level2) or Update(Reason_Level3) or Update(Reason_Level4) or Update(Research_Close_Date) or Update(Research_Comment_Id) or Update(Research_Open_Date) or Update(Research_Status_Id) or Update(Research_User_Id) or Update(Signature_Id) or Update(Source_PU_Id) or Update(Start_Time) or Update(Summary_Action_Comment_Id) or Update(Summary_Cause_Comment_Id) or Update(Summary_Research_Comment_Id) or Update(TEDet_Id) or Update(TEFault_Id) or Update(TEStatus_Id) or Update(Uptime) or Update(User_Id) or Update(Work_Order_Number)) 
   Begin
 	  	   Insert Into Timed_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,End_Time,Event_Reason_Tree_Data_Id,Initial_User_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Time,Summary_Action_Comment_Id,Summary_Cause_Comment_Id,Summary_Research_Comment_Id,TEDet_Id,TEFault_Id,TEStatus_Id,Uptime,User_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.End_Time,a.Event_Reason_Tree_Data_Id,a.Initial_User_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Time,a.Summary_Action_Comment_Id,a.Summary_Cause_Comment_Id,a.Summary_Research_Comment_Id,a.TEDet_Id,a.TEFault_Id,a.TEStatus_Id,a.Uptime,a.User_Id,a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
 
 
 CREATE TRIGGER [dbo].[Local_TimedEventDetails_AddNPT] 
   ON [dbo].[Timed_Event_Details] 
   AFTER INSERT 
   AS 
  	  
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge 
 Declare   @Start Int ,  @End int 
 DECLARE @MyPUId Int,@MyStartTime DateTime,@MyEndTime DateTime 
 DECLARE @RL1 Int,@MyUserId Int 
 DECLARE @Now Datetime 
 DECLARE
		@PUID			INT,                    --this is the pu_id in question
		@ActivePath		INT                           --this is the path_id from dbo.production_plan where hte order is active for the unit in question
 -- 
 -- 
 DECLARE 
 		@EODHour		NVARCHAR(2)		, 
 		@EODMin			NVARCHAR(2)		, 
 		@EODHourParId	INT				, 
 		@EODMinParId	INT				, 
 		@STODTime		NVARCHAR(6)		, 
 		@After21Days	DATE			, 
 		@comxId			INT 			,
		@idx			INT				,
		@idxMax			INT	

DECLARE @Units	TABLE		(
		Id						INT IDENTITY(1,1)		,
		PUId					INT						)
 --  
 
 
 SELECT @Now = dbo.fnServer_CmnConvertToDbTime(getutcdate(),'UTC') 
 DECLARE @InsertedData Table (Id Int Identity(1,1) 
 							,PUId Int  Null 
 							,StartTime DateTime  Null 
 							,EndTime DateTime Null 
 							,ReasonLevel1 Int  Null 
 							,UserId Int  Null) 
 
 
 INSERT INTO @InsertedData(PUId,StartTime,EndTime,ReasonLevel1,UserId) 
    SELECT  PU_Id, Start_Time,End_Time,Reason_Level1,User_Id  
    FROM INSERTED i 	
    JOIN dbo.Event_Reasons						er		(NOLOCK) ON i.Reason_Level1 = er.Event_Reason_Id 
	LEFT JOIN dbo.Event_Reason_Category_Data	ercd	(NOLOCK) ON ercd.Event_Reason_Tree_Data_Id = i.Event_Reason_Tree_Data_Id
	LEFT JOIN dbo.Event_Reason_Catagories		erc		(NOLOCK) ON erc.ERC_Id = ercd.ERC_Id
WHERE erc.erc_desc = 'Non-Productive Time'

    --JOIN  dbo.Event_Reasons er ON i.Reason_Level1 = er.Event_Reason_Id 
    --WHERE Event_Reason_Name like '%STNU%' 
 
--we need to get all the units fro the active order for the unit of the donwtime entry      
SELECT @ActivePath = pp.Path_Id
FROM dbo.Production_Plan pp (NOLOCK) 
    JOIN dbo.PrdExec_Path_Units pathUnits (NOLOCK) ON pathunits.Path_Id = pp.Path_Id
    JOIN dbo.Production_Plan_Statuses ppstatus (NOLOCK) ON ppstatus.PP_Status_Id = pp.PP_Status_Id
	JOIN @InsertedData ud ON pathUnits.PU_Id = ud.PUId
WHERE ppstatus.PP_Status_Desc = 'Active'
	   
-- Get all the Units from Execution Path
---------------------------------------------------------------------------------------------------
INSERT INTO  @Units (PUId)
SELECT DISTINCT pu.PU_Id 
FROM dbo.PrdExec_Path_Units pathunits (NOLOCK) 
      JOIN dbo.Prod_Units_Base pu (NOLOCK) ON pu.PU_Id = pathunits.PU_Id
WHERE pathunits.Path_Id = @ActivePath
      AND pu.Non_Productive_Reason_TREE IS NOT NULL

 
 IF NOT EXISTS (SELECT * FROM @InsertedData) 
 BEGIN 
 		RETURN 
 END 
 
 
 -- Get the start of the day from the Site Parameters table in case there is no Crew Schedule 
 SELECT @EODHourParId = Parm_Id FROM dbo.Parameters (NOLOCK) WHERE Parm_Name LIKE '%EndOfDayHour%' 
 SELECT @EODMinParId = Parm_Id FROM dbo.Parameters (NOLOCK) WHERE Parm_Name LIKE '%EndOfDayMinute%' 
 -- 
SELECT @EODHour = ISNULL(Value,'00') FROM dbo.Site_Parameters (NOLOCK) WHERE Parm_id = @EODHourParId 
 SELECT @EODMin = ISNULL(Value,'00') FROM dbo.Site_Parameters (NOLOCK) WHERE Parm_id = @EODMinParId 
 -- 
 SET @STODTime = @EODHour + ':' + @EODMin 
 -- 
 -- Get comxclient user: 
 SElECT @comxId = User_Id FROM dbo.Users (NOLOCK) WHERE UserName = 'ComXClient' 
 -- 
 
 
 --INSERT INTO dbo.Local_Debug (Timestamp,CallingSP, Message) 
 --VALUES (GETDATE(),'Local_TimedEventDetails_AddNPT','Firing') 
 
 
 SET @End = @@ROWCOUNT 
 SET @Start = 1 
 WHILE  @Start <= @End 
 BEGIN 
		SET @idx = 1
		SELECT @idxMax = COUNT(*) FROM @Units

		WHILE @idx <= @idxMax
		BEGIN
	
			SELECT @MyPUId = PUId
			FROM @Units
			WHERE Id = @idx
 
 			SELECT @MyStartTime = StartTime,@MyEndTime = EndTime 
 					,@RL1 = ReasonLevel1,@MyUserId = UserId  
 			FROM @InsertedData  
 			WHERE Id = @Start 
 			-- If the Stop Just happens then set the End Time of the STNU on the NPT in the next 7 days 
 			IF @MyEndTime Is NULL  
 			BEGIN 
				SET @MyEndTime = 	dateadd(day,21,@MyStartTime)  -- added for FO-02742
						-- commnted for FO-02742
 						--SET @MyEndTime = 	
 						--	(CASE 	WHEN DATENAME(dw,dateadd(day,1,@MyStartTime))='Monday' THEN dateadd(day,1,@MyStartTime) 
 						--			WHEN datename(dw,dateadd(day,2,@MyStartTime))='Monday' THEN dateadd(day,2,@MyStartTime) 
							--	    WHEN datename(dw,dateadd(day,3,@MyStartTime))='Monday' THEN dateadd(day,3,@MyStartTime) 
							--		WHEN datename(dw,dateadd(day,4,@MyStartTime))='Monday' THEN dateadd(day,4,@MyStartTime) 
							--		WHEN datename(dw,dateadd(day,5,@MyStartTime))='Monday' THEN dateadd(day,5,@MyStartTime) 
							--		WHEN datename(dw,dateadd(day,6,@MyStartTime))='Monday' THEN dateadd(day,6,@MyStartTime) 
							--		WHEN datename(dw,dateadd(day,7,@MyStartTime))='Monday' THEN dateadd(day,7,@MyStartTime) 
 						--	END) --DATEADD(DAY,7,@MyStartTime)	SET @MyEndTime = DATEADD(DAY,7,@MyStartTime) 
 	 
 					IF EXISTS (SELECT * FROM dbo.Crew_Schedule (NOLOCK) WHERE PU_Id = @MyPUId AND CONVERT(DATE,@MyEndTime) BETWEEN Start_Time AND End_Time) 
 					BEGIN 
 							SET @MyEndTime = (SELECT End_Time FROM dbo.Crew_Schedule (NOLOCK) WHERE PU_Id = @MyPUId AND CONVERT(DATE,@MyEndTime) BETWEEN Start_Time AND End_Time) 
 					END 
 					ELSE 
 					BEGIN 
 							-- Make next Monday the Start of the Production Day 
 							SET	@After21Days = @MyEndTime 
 							SELECT @MyEndTime = CONVERT(DATETIME,CONVERT(NVARCHAR,@After21Days) + ' ' + @STODTime) 
 					END 
 
						IF EXISTS (Select * from dbo.NonProductive_Detail (NOLOCK) Where pu_id = @MyPUId and Start_time >@MyStartTime  and Start_time < @MyEndTime )
						Begin 
								SET @MyEndTime = (Select top 1 Start_time from dbo.NonProductive_Detail (NOLOCK) Where pu_id = @MyPUId and Start_time >@MyStartTime and Start_time < @MyEndTime  order by start_time asc)
						END
 
 					BEGIN TRY 
 						-- The original NPT will be create by ComXClient: 
 						EXEC dbo.spServer_DBMgrUpdNonProductiveTime
									@NPDetId = Null 
 									,@PUId = @MyPUId 
 									,@StartTime = @MyStartTime 
 									,@EndTime = @MyEndTime 
 									,@ReasonLevel1 = @RL1 
 									,@ReasonLevel2 = Null 
 									,@ReasonLevel3 = Null 
 									,@ReasonLevel4 = Null 
 									,@TransactionType = 1 
 									,@TransNum = 0 
 									,@UserId = @comxId --@MyUserId 
 									,@CommentId = 0 
 									,@ERTDataId = Null 
 									,@EntryOn = @Now 
 									,@ReturnAllResults =  1 
 					END TRY 
 					BEGIN CATCH 
 					END CATCH 
 			  END 

			  SET @idx = @idx + 1
		END
        SET @Start = @Start + 1 
 END 
 
 


GO
DISABLE TRIGGER [dbo].[Local_TimedEventDetails_AddNPT]
    ON [dbo].[Timed_Event_Details];


GO
CREATE TRIGGER [dbo].[Timed_Event_Details_History_Del]
 ON  [dbo].[Timed_Event_Details]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 400
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Timed_Event_Detail_History
 	  	   (Action_Comment_Id,Action_Level1,Action_Level2,Action_Level3,Action_Level4,Amount,Cause_Comment_Id,End_Time,Event_Reason_Tree_Data_Id,Initial_User_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Signature_Id,Source_PU_Id,Start_Time,Summary_Action_Comment_Id,Summary_Cause_Comment_Id,Summary_Research_Comment_Id,TEDet_Id,TEFault_Id,TEStatus_Id,Uptime,User_Id,Work_Order_Number,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action_Level1,a.Action_Level2,a.Action_Level3,a.Action_Level4,a.Amount,a.Cause_Comment_Id,a.End_Time,a.Event_Reason_Tree_Data_Id,a.Initial_User_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Signature_Id,a.Source_PU_Id,a.Start_Time,a.Summary_Action_Comment_Id,a.Summary_Cause_Comment_Id,a.Summary_Research_Comment_Id,a.TEDet_Id,a.TEFault_Id,a.TEStatus_Id,a.Uptime,coalesce(@NEWUserId,a.User_Id),a.Work_Order_Number,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO

-----------------------------------------------------------------------------------------------------------------------------------------------
--
--	2017-08-10	Version 1.0			Initial Version
--
-----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER [dbo].[Tri_Local_TimedEventDetails_NPDetail]
	ON [dbo].[Timed_Event_Details]
	AFTER INSERT,UPDATE
	AS
       
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge

DECLARE 
		@Start					INT						,  
		@End					INT						,
		@MyPUId					INT						,
		@MyStartTime			DATETIME				,
		@MyEndTime				DATETIME				,
		@TEDetId				INT						,
		@RL1					INT						,
		@MyUserId				INT						,
		@Now					DATETIME				,
		@DelStartTime			DATETIME				,
		@NPDetId				INT
--
DECLARE
		@EODHour				NVARCHAR(2)				,
		@EODMin					NVARCHAR(2)				,
		@EODHourParId			INT						,
		@EODMinParId			INT						,
		@STODTime				NVARCHAR(6)				,
		@NextMonday				DATE
--

DECLARE 
		@OldTEDetId				INT						,
		@OldPUId				INT						,
		@OldSourcePUId			INT						,
		@OldStartTime			DATETIME				,
		@OldEndTime				DATETIME				,
		@OldReasonLevel1		INT						,
		@OldReasonLevel2		INT						,
		@OldReasonLevel3		INT						,
		@OldReasonLevel4		INT						,
		@OldUserId				INT						,
		@OldDelayTreeId			INT						,
		@OldDelayTreeNodeId		INT						,
		@OldDelayCategoryDesc	NVARCHAR(30)			
--

DECLARE 
		@InsTEDetId				INT						,
		@InsPUId				INT						,
		@InsSourcePUId			INT						,
		@InsStartTime			DATETIME				,
		@InsEndTime				DATETIME				,
		@InsReasonId			INT						,
		@InsReasonLevel1		INT						,
		@InsReasonLevel2		INT						,
		@InsReasonLevel3		INT						,
		@InsReasonLevel4		INT						,
		@InsUserId				INT						,
		@InsDelayTreeId			INT						,
		@InsDelayTreeNodeId		INT						,
		@InsDelayCategoryDesc	NVARCHAR(30)			
--

DECLARE @UpdatedData Table		(
		Id						INT IDENTITY(1,1)		,
		TEDetId					INT				NULL	,
		PUId					INT				NULL	,
		SourcePUId				INT				NULL	,
		StartTime				DATETIME		NULL	,
		EndTime					DATETIME		NULL	,
		ReasonLevel1			INT				NULL	,
		ReasonLevel2			INT				NULL	,
		ReasonLevel3			INT				NULL	,
		ReasonLevel4			INT				NULL	,
		UserId					INT				NULL	,
		DelayTreeId				INT				NULL	,
		DelayTreeNodeId			INT				NULL	,
		DelayCategoryDesc		NVARCHAR(30)	NULL	,
		ReasonName				NVARCHAR(30)	NULL	)

SELECT @Now = dbo.fnServer_CmnConvertToDbTime(getutcdate(),'UTC')

INSERT INTO @UpdatedData(
				TEDetId			,
				PUId			,
				StartTime		,
				EndTime			,
				ReasonLevel1	,
				ReasonLevel2	,
				ReasonLevel3	,
				ReasonLevel4	,
				UserId			)

   SELECT		i.TEDet_Id		, 
				i.PU_Id			, 
				i.Start_Time	, 
				i.End_Time		, 
				i.Reason_Level1	, 
				i.Reason_Level2	, 
				i.Reason_Level3	, 
				i.Reason_Level4	, 
				i.User_Id 
   FROM INSERTED i

--=================================================================================================
-- Update Downtimes Detail: Determine which Reason trees are associated with the PUID's
---------------------------------------------------------------------------------------------------
UPDATE 		ud
	SET 	DelayTreeId = pe.Name_Id
	FROM	@UpdatedData ud 
	JOIN 	dbo.Prod_Events pe	WITH(NOLOCK) 
								ON COALESCE(ud.SourcePUId, ud.PUID) = pe.PU_Id
	WHERE	pe.Event_Type = 2 
	
---------------------------------------------------------------------------------------------------
-- Update Downtimes Detail: Find the node ID associated with Reason Tree Level 4
---------------------------------------------------------------------------------------------------
IF	(SELECT Count(ReasonLevel4) FROM @UpdatedData) > 0
BEGIN 
	UPDATE		ud
		SET 	DelayTreeNodeId = l4.Event_Reason_Tree_Data_Id 	-- tree node_Node_Id
		FROM	@UpdatedData 					ud		
		JOIN	dbo.Event_Reasons 				er	WITH(NOLOCK)	ON	ud.ReasonLevel4 		= er.Event_Reason_Id
		JOIN	dbo.Event_Reason_Tree_Data 		l4	WITH(NOLOCK)	ON	ud.DelayTreeId 			= l4.Tree_Name_Id
																	AND	ud.ReasonLevel4 		= l4.Event_Reason_Id
																	AND	l4.Event_Reason_Level 	= 4

	UPDATE		ud  
		SET		DelayCategoryDesc = ec.ERC_Desc
		FROM	@UpdatedData					ud  
		JOIN	dbo.Event_Reason_Category_Data	ed	WITH (NOLOCK)	ON ud.DelayTreeNodeId	= ed.Event_Reason_Tree_Data_Id  
		JOIN	dbo.Event_Reason_Catagories		ec	WITH (NOLOCK)	ON ec.ERC_Id			= ed.ERC_Id   
END
 
---------------------------------------------------------------------------------------------------
-- Update Downtimes Detail: Find the node ID associated with Reason Tree Level 3
---------------------------------------------------------------------------------------------------
IF	(SELECT Count(ReasonLevel3) FROM @UpdatedData) > 0
BEGIN 
	UPDATE		ud
		SET 	DelayTreeNodeId = l3.Event_Reason_Tree_Data_Id 	-- tree node_Node_Id
		FROM	@UpdatedData 					ud		
		JOIN	dbo.Event_Reasons 				er	WITH(NOLOCK)	ON	ud.ReasonLevel3 		= er.Event_Reason_Id
		JOIN	dbo.Event_Reason_Tree_Data 		l3	WITH(NOLOCK)	ON	ud.DelayTreeId 			= l3.Tree_Name_Id
																	AND	ud.ReasonLevel3 		= l3.Event_Reason_Id
																	AND	l3.Event_Reason_Level	= 3

	UPDATE		ud  
		SET		DelayCategoryDesc = ec.ERC_Desc
		FROM	@UpdatedData					ud  
		JOIN	dbo.Event_Reason_Category_Data	ed	WITH (NOLOCK)	ON ud.DelayTreeNodeId	= ed.Event_Reason_Tree_Data_Id  
		JOIN	dbo.Event_Reason_Catagories		ec	WITH (NOLOCK)	ON ec.ERC_Id			= ed.ERC_Id   
END


---------------------------------------------------------------------------------------------------
-- Update Downtimes Detail. Find the node ID associated with Reason Tree Level 2
---------------------------------------------------------------------------------------------------
IF	(SELECT Count(ReasonLevel2) FROM @UpdatedData) > 0
BEGIN 
	UPDATE		ud
		SET 	DelayTreeNodeId = l2.Event_Reason_Tree_Data_Id 	-- tree node_Node_Id
		FROM	@UpdatedData 					ud		
		JOIN	dbo.Event_Reasons 				er	WITH(NOLOCK)	ON	ud.ReasonLevel2 		= er.Event_Reason_Id
		JOIN	dbo.Event_Reason_Tree_Data 		l2	WITH(NOLOCK)	ON	ud.DelayTreeId 			= l2.Tree_Name_Id
																	AND	ud.ReasonLevel2 		= l2.Event_Reason_Id
																	AND	l2.Event_Reason_Level	= 2

	UPDATE		ud  
		SET		DelayCategoryDesc = ec.ERC_Desc
		FROM	@UpdatedData					ud  
		JOIN	dbo.Event_Reason_Category_Data	ed	WITH (NOLOCK)	ON ud.DelayTreeNodeId	= ed.Event_Reason_Tree_Data_Id  
		JOIN	dbo.Event_Reason_Catagories		ec	WITH (NOLOCK)	ON ec.ERC_Id			= ed.ERC_Id   
END

---------------------------------------------------------------------------------------------------
-- Update Downtimes Detail. Find the node ID associated with Reason Tree Level 1
---------------------------------------------------------------------------------------------------
IF	(SELECT Count(ReasonLevel1) FROM @UpdatedData) > 0
BEGIN 
	UPDATE		ud
		SET 	DelayTreeNodeId = l1.Event_Reason_Tree_Data_Id 	-- tree node_Node_Id
		FROM	@UpdatedData 					ud		
		JOIN	dbo.Event_Reasons 				er	WITH(NOLOCK)	ON	ud.ReasonLevel1 		= er.Event_Reason_Id
		JOIN	dbo.Event_Reason_Tree_Data 		l1	WITH(NOLOCK)	ON	ud.DelayTreeId 			= l1.Tree_Name_Id
																	AND	ud.ReasonLevel1 		= l1.Event_Reason_Id
																	AND	l1.Event_Reason_Level	= 1

	UPDATE		ud  
		SET		DelayCategoryDesc = ec.ERC_Desc
		FROM	@UpdatedData					ud  
		JOIN	dbo.Event_Reason_Category_Data	ed	WITH (NOLOCK)	ON ud.DelayTreeNodeId	= ed.Event_Reason_Tree_Data_Id  
		JOIN	dbo.Event_Reason_Catagories		ec	WITH (NOLOCK)	ON ec.ERC_Id			= ed.ERC_Id   
END

---------------------------------------------------------------------------------------------------
-- Filter Downtimes by PR Out category
---------------------------------------------------------------------------------------------------
DELETE FROM @UpdatedData
WHERE DelayCategoryDesc NOT LIKE 'Non-Productive%'


IF NOT EXISTS (SELECT * FROM @UpdatedData)
BEGIN
		RETURN
END

---------------------------------------------------------------------------------------------------
-- Get record to be updated
---------------------------------------------------------------------------------------------------
SELECT	@OldTEDetId			=	d.TEDet_Id			, 
		@OldPUId			=	d.PU_Id				, 
		@OldSourcePUId		=	d.Source_PU_Id		,
		@OldStartTime		=	d.Start_Time		, 
		@OldEndTime			=	d.End_Time			, 
		@OldReasonLevel1	=	d.Reason_Level1		, 
		@OldReasonLevel2	=	d.Reason_Level2		, 
		@OldReasonLevel3	=	d.Reason_Level3		, 
		@OldReasonLevel4	=	d.Reason_Level4		, 
		@OldUserId			=	d.User_Id 
FROM DELETED d

---------------------------------------------------------------------------------------------------
UPDATE @UpdatedData
	SET ReasonName = CASE
							WHEN DelayCategoryDesc LIKE 'Non-Productive%' THEN 'PR Out:STNU'
							END


SELECT	@InsTEDetId			=	ud.TEDetId			, 
		@InsPUId			=	ud.PUId			, 
		@InsSourcePUId		=	ud.SourcePUId		,
		@InsStartTime		=	ud.StartTime		, 
		@InsEndTime			=	ud.EndTime			, 
		@InsReasonId		=	er.Event_Reason_Id	,
		@InsReasonLevel1	=	ud.ReasonLevel1	, 
		@InsReasonLevel2	=	ud.ReasonLevel2	, 
		@InsReasonLevel3	=	ud.ReasonLevel3	, 
		@InsReasonLevel4	=	ud.ReasonLevel4	,
		@InsUserId			=	ud.UserId 
FROM @UpdatedData		ud
JOIN dbo.Event_Reasons	er	WITH(NOLOCK) ON ud.ReasonName = er.Event_Reason_Name

	--insert into Local_DebugTrigger(
	--			OldPUId				,
	--			OldStartTime		,
	--			OldEndTime			,
	--			PUId				,
	--			StartTime			,
	--			EndTime				,
	--			NPDetId				,
	--			ReasonLevel1		,
	--			comment				)
	--values(
	--			@OldPUId			,
	--			@OldStartTime		,
	--			@OldEndTime			,
	--			@InsPUId				,
	--			@InsStartTime			,
	--			@InsEndTime			,
	--			@NPDetId			,
	--			@InsReasonLevel1	,
	--			'before'			)

-- Get the start of the day from the Site Parameters table in case there is no Crew Schedule
--


IF @InsEndTime IS NOT NULL
BEGIN
	-- The Stop Closes, look for the associated NPT:
	SELECT		@NPDetId = NPDet_Id 
	FROM	dbo.NonProductive_Detail	npd	WITH(NOLOCK)
	JOIN	@UpdatedData				ud	ON npd.PU_Id = ud.PUId 
							AND npd.Start_Time = @OldStartTime
              
	--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message)
	--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','1st IF @NPDetId IS NOT NULL')
	-- Update the NPT with the New End_Time
	IF @NPDetId IS NOT NULL
	BEGIN
	--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message)
	--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','1st IF @NPDetId IS NOT NULL Trying to MOdify')
		BEGIN TRY
			EXECUTE spServer_DBMgrUpdNonProductiveTime 						
								@NPDetId = @NPDetId							
								,@PUId = @InsPUId							
								,@StartTime = @InsStartTime					
								,@EndTime = @InsEndTime						
								,@ReasonLevel1 = @InsReasonId			
								,@ReasonLevel2 = NULL			
								,@ReasonLevel3 = NULL			
								,@ReasonLevel4 = NULL			
								,@TransactionType = 2						
								,@TransNum = 0
								,@UserId = @InsUserId
								,@CommentId = 0
								,@ERTDataId = Null
								,@EntryOn = @Now
								,@ReturnAllResults =  0
		END TRY
		BEGIN CATCH
		END CATCH
	END
END
ELSE
BEGIN
	
					--INSERT INTO dbo.Local_Debug (Timestamp, CallingSP, Message)
						--VALUES (GETDATE(), 'Local_TimedEventDetails_UpdateNPT','1st ELSE @NPDetId IS NOT NULL')

	SET @InsEndTime = DATEADD(MONTH,6,@InsStartTime)
	
	BEGIN TRY
		EXECUTE spServer_DBMgrUpdNonProductiveTime 						
							@NPDetId = NULL							
							,@PUId = @InsPUId							
							,@StartTime = @InsStartTime					
							,@EndTime = @InsEndTime						
							,@ReasonLevel1 = @InsReasonId			
							,@ReasonLevel2 = NULL			
							,@ReasonLevel3 = NULL			
							,@ReasonLevel4 = NULL			
							,@TransactionType = 1						
							,@TransNum = 0
							,@UserId = @InsUserId
							,@CommentId = 0
							,@ERTDataId = Null
							,@EntryOn = @Now
							,@ReturnAllResults =  0
	END TRY
	BEGIN CATCH
	END CATCH

END




	--insert into Local_DebugTrigger(
	--			OldPUId				,
	--			OldStartTime		,
	--			OldEndTime			,
	--			PUId				,
	--			StartTime			,
	--			EndTime				,
	--			NPDetId				,
	--			ReasonLevel1		,
	--			comment				)
	--values(
	--			@OldPUId			,
	--			@OldStartTime		,
	--			@OldEndTime			,
	--			@InsPUId				,
	--			@InsStartTime			,
	--			@InsEndTime			,
	--			@NPDetId			,
	--			@InsReasonLevel1	,
	--			'after'			)
GO
DISABLE TRIGGER [dbo].[Tri_Local_TimedEventDetails_NPDetail]
    ON [dbo].[Timed_Event_Details];


GO
CREATE TRIGGER dbo.Timed_Event_Details_Upd
  ON dbo.Timed_Event_Details
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
  @This_Time datetime,
  @This_Unit int,
  @This_EventId int
DECLARE Timed_Event_Details_Upd_Cursor CURSOR
  FOR SELECT TEDet_Id, PU_Id, Start_Time FROM INSERTED
  FOR READ ONLY
OPEN Timed_Event_Details_Upd_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Timed_Event_Details_Upd_Cursor INTO @This_EventId, @This_Unit, @This_Time
  IF @@FETCH_STATUS = 0
    BEGIN
      Execute spServer_CmnAddScheduledTask @This_EventId,3,@This_Unit, @This_Time
      Select @This_EventId = NULL
      Select @This_EventId = TEDEt_Id, @This_Time = Start_Time
       	 from Timed_Event_Details 
       	 where (pu_id = @This_Unit) and 
 	       (Start_Time = (select min(Start_Time) from Timed_Event_Details where (pu_id = @This_Unit) and (Start_Time > @This_Time)))
      If (@This_EventId Is Not NULL)
        Begin
          Execute spServer_CmnAddScheduledTask @This_EventId,3,@This_Unit, @This_Time
        End
      GOTO Fetch_Next_Event
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error in Timed_Event_Details_Upd (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
    END
  DEALLOCATE Timed_Event_Details_Upd_Cursor

GO
CREATE TRIGGER dbo.Timed_Event_Details_Ins
  ON dbo.Timed_Event_Details
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
  @This_Time datetime,
  @This_Unit int,
  @This_EventId int
DECLARE Timed_Event_Details_Ins_Cursor CURSOR
  FOR SELECT TEDET_Id, PU_Id, Start_Time FROM INSERTED
  FOR READ ONLY
OPEN Timed_Event_Details_Ins_Cursor
  Fetch_Next_Event:
  FETCH NEXT FROM Timed_Event_Details_Ins_Cursor INTO @This_EventId, @This_Unit, @This_Time
  IF @@FETCH_STATUS = 0
    BEGIN
      Execute spServer_CmnAddScheduledTask @This_EventId,3,@This_Unit,@This_Time
      Select @This_EventId = NULL
      Select @This_EventId = TEDet_Id, @This_Time = Start_Time From Timed_Event_Details 
       	 where (pu_id = @This_Unit) and 
 	       (Start_Time = (select min(Start_Time) from Timed_Event_Details where (pu_id = @This_Unit) and (Start_Time > @This_Time)))
      If (@This_EventId Is Not NULL)
        Begin
          Execute spServer_CmnAddScheduledTask @This_EventId,3,@This_Unit,@This_Time
        End
      GOTO Fetch_Next_Event
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error in Timed_Event_Detail_Ins (@@FETCH_STATUS = %d).', 11,-1, @@FETCH_STATUS)
    END
DEALLOCATE Timed_Event_Details_Ins_Cursor
