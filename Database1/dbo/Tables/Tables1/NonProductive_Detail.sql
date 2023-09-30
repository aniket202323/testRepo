CREATE TABLE [dbo].[NonProductive_Detail] (
    [NPDet_Id]                  INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]                INT      NULL,
    [End_Time]                  DATETIME NOT NULL,
    [Entry_On]                  DATETIME NOT NULL,
    [Event_Reason_Tree_Data_Id] INT      NULL,
    [PU_Id]                     INT      NOT NULL,
    [Reason_Level1]             INT      NULL,
    [Reason_Level2]             INT      NULL,
    [Reason_Level3]             INT      NULL,
    [Reason_Level4]             INT      NULL,
    [Start_Time]                DATETIME NOT NULL,
    [User_Id]                   INT      NULL,
    [NPT_Group_Id]              INT      NULL,
    CONSTRAINT [NPDetail_PK_NPDetId] PRIMARY KEY NONCLUSTERED ([NPDet_Id] ASC),
    CONSTRAINT [NPDetail_CC_StartTimeEndTime] CHECK ([End_Time]>[Start_Time]),
    CONSTRAINT [NPDetail_FK_NPTGroupId] FOREIGN KEY ([NPT_Group_Id]) REFERENCES [dbo].[NPT_Detail_Grouping] ([NPT_Group_Id]),
    CONSTRAINT [NPDetail_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE CASCADE,
    CONSTRAINT [NPDetail_FK_RsnLevel1] FOREIGN KEY ([Reason_Level1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [NPDetail_FK_RsnLevel2] FOREIGN KEY ([Reason_Level2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [NPDetail_FK_RsnLevel3] FOREIGN KEY ([Reason_Level3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [NPDetail_FK_RsnLevel4] FOREIGN KEY ([Reason_Level4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [NPDetail_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [NPDetail_IDX_PUIdSTimeETime]
    ON [dbo].[NonProductive_Detail]([PU_Id] ASC, [Start_Time] ASC, [End_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [NPDetail_IDX_NPTGroupId]
    ON [dbo].[NonProductive_Detail]([NPT_Group_Id] ASC);


GO
CREATE TRIGGER [dbo].[NonProductive_Detail_History_Ins]
 ON  [dbo].[NonProductive_Detail]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 436
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into NonProductive_Detail_History
 	  	   (Comment_Id,End_Time,Entry_On,Event_Reason_Tree_Data_Id,NPDet_Id,NPT_Group_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Entry_On,a.Event_Reason_Tree_Data_Id,a.NPDet_Id,a.NPT_Group_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
 
 
-- =============================================
-- Author:			Akshay Kasurde
-- Create date:		2019-11-13
-- Description:		Trigger to populate the NPT event defined on a particular unit to all other units on the execution path. 
--					Trigger will only work when there is an active PO on the line.
-- =============================================

 ----------------------------------------------------------------------------------------------------------------------------------------------- 
 --Version History
 --	2019-11-13	Version 1.0		Akshay Kasurde		Initial Version 
 -- 2020-03-26	Version	1.2		Akshay Kasurde		Changed the Order of Delete and Insert code within the Trigger. First Execute delete condition
 --													and then Insert condition 
 
 -----------------------------------------------------------------------------------------------------------------------------------------------


CREATE TRIGGER dbo.[TRI_Local_NonProductiveDetail_FollowActivePath]
   ON  dbo.[NonProductive_Detail]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	
	SET NOCOUNT ON;

    -- Declare all the Variables and Local Tables required for the logic
	DECLARE	@LoopCnt				INT,
				@Idx				INT,
				@ActivePath			INT,
				@NPDetId			INT,
				@StartTime			DATETIME, 
				@EndTime			DATETIME,	
				@Now				DATETIME,
				@ReasonLevel1		INT	,
				@UserId				INT,
				@ReasonTreeDataId	INT,
				@PUID				INT,
				@error				INT

	DECLARE	@InsertedItems TABLE (	Idx				INT	Identity,
									NPDetId			INT,
									PUID			INT,
									StartTime		DATETIME,
									EndTime			DATETIME,
									ReasonLevel1	INT,
									UserId			INT,
									ERTDataID		INT)

	DECLARE	@DeletedItems TABLE (	Idx				INT	IDENTITY ,
									NPDetId			INT,
									PUID			INT,
									StartTime		DATETIME,
									EndTime			DATETIME,
									ReasonLevel1	INT,
									UserId			INT,
									ERTDataID		INT)

	DECLARE	@ItemsToDelete TABLE (	Idx				INT	IDENTITY ,
									NPDetId			INT,
									PUID			INT,
									StartTime		DATETIME,
									EndTime			DATETIME,
									ReasonLevel1	INT,
									UserId			INT,
									ERTDataID		INT)


	DECLARE	@Units TABLE	(		Idx		INT IDENTITY,
									PUID	INT)



	SET @Now = (Select GETDATE())

		-- Delete Trigger Functionality Begins here

	INSERT INTO @DeletedItems( NPDetId, PUID, StartTime, EndTime, ReasonLevel1, UserId, ERTDataId)
	SELECT NPDet_Id, PU_ID, STart_Time, End_Time, Reason_Level1, User_Id, Event_Reason_Tree_Data_Id
	FROM	Deleted		d

	IF EXISTS ( SELECT * FROM @DeletedItems)
	BEGIN
		SET	@Idx= 1
		--Loop through all the Deleted items at a particular time. To support multiple deletes
		WHILE @Idx <= (Select Max(Idx) from @DeletedItems)
		BEGIN
			SELECT @ActivePath = pp.Path_Id
			FROM dbo.Production_Plan pp (NOLOCK) 
					JOIN dbo.PrdExec_Path_Units pathUnits (NOLOCK) ON pathunits.Path_Id = pp.Path_Id
				JOIN dbo.Production_Plan_Statuses ppstatus (NOLOCK) ON ppstatus.PP_Status_Id = pp.PP_Status_Id
				JOIN @DeletedItems ud ON pathUnits.PU_Id = ud.PUId
			WHERE ud.Idx = @Idx AND ppstatus.PP_Status_Desc = 'Active'
	   
		-- Get all the Units from Execution Path
		---------------------------------------------------------------------------------------------------
			INSERT INTO  @Units (PUId)
			SELECT DISTINCT pu.PU_Id 
			FROM dbo.PrdExec_Path_Units pathunits (NOLOCK) 
				JOIN dbo.Prod_Units_Base pu (NOLOCK) ON pu.PU_Id = pathunits.PU_Id
			WHERE pathunits.Path_Id = @ActivePath
				AND pu.Non_Productive_Reason_TREE IS NOT NULL

				
				SELECT @StartTime	 =StartTime , 
					@EndTime			= 	EndTime,		
					@ReasonLevel1		= 	ReasonLevel1	,
					@UserId =  UserId,
					@ReasonTreeDataId = ERTDataId
			FROM	@DeletedItems 
			WHERE	Idx= @Idx


				
			SET @LoopCnt = 1
			-- Loop through the list of units on active path.
			WHILE @LoopCnt <= (SELECT Max(Idx) FROM @Units)
			BEGIN
				SELECT @PUID = PUID FROM @Units WHERE Idx = @LoopCnt
				SET @NPDetId = Coalesce ((SELECT NPDet_ID 
									FROM	NonProductive_Detail  NPT
									WHERE	pu_id =  @PUID 
											AND		Start_Time = @StartTime
											AND		End_Time = @EndTime), NULL)


				IF @NPDetId IS NOT NULL
				BEGIN
					BEGIN TRY
							EXEC dbo.spServer_DBMgrUpdNonProductiveTime 
											@NPDetId			= @NPDetId				
											,@PUId				= @PUId 			
											,@StartTime			= @StartTime		
											,@EndTime			= @EndTime			
											,@ReasonLevel1		= Null		
											,@ReasonLevel2		= Null				
											,@ReasonLevel3		= Null				
											,@ReasonLevel4		= Null				
											,@TransactionType	= 3				
											,@TransNum			= 0					
											,@UserId			= @UserId			
											,@CommentId			= 0					
											,@ERTDataId			= Null	
											,@EntryOn			= @Now	
											,@NPTGroupId		= Null				
											,@ReturnAllResults	=  0
						END TRY
						BEGIN CATCH
							SET @error = 1
						END CATCH
						IF @error = 1
							BREAK
				END

			SET @LoopCnt= @LoopCnt +1
			END

		DELETE FROM @Units
		SET @Idx = @Idx +1
		END

	END


		-- Insert Trigger Functionality Begins here
	INSERT INTO @InsertedItems( PUID, StartTime, EndTime, ReasonLevel1, UserId, ERTDataId)
	SELECT PU_ID, STart_Time, End_Time, Reason_Level1, User_Id, Event_Reason_Tree_Data_Id
	FROM	Inserted		i


	IF EXISTS (SELECT * FROM @InsertedItems)
	BEGIN
		SET	@Idx= 1
		-- Loop through all the inserts made at a particular time. To support muliple inserts.
		WHILE @Idx <= (SELECT Max(Idx) FROM @InsertedItems)
		BEGIN
				SELECT @ActivePath = pp.Path_Id
				FROM dbo.Production_Plan pp (NOLOCK) 
					 JOIN dbo.PrdExec_Path_Units pathUnits (NOLOCK) ON pathunits.Path_Id = pp.Path_Id
					JOIN dbo.Production_Plan_Statuses ppstatus (NOLOCK) ON ppstatus.PP_Status_Id = pp.PP_Status_Id
					JOIN @InsertedItems ud ON pathUnits.PU_Id = ud.PUId
				WHERE ud.Idx = @Idx AND ppstatus.PP_Status_Desc = 'Active'
	   
			-- Get all the Units from Execution Path for the active PO
			---------------------------------------------------------------------------------------------------
				INSERT INTO  @Units (PUId)
				SELECT DISTINCT pu.PU_Id 
				FROM dbo.PrdExec_Path_Units pathunits (NOLOCK) 
				  JOIN dbo.Prod_Units_Base pu (NOLOCK) ON pu.PU_Id = pathunits.PU_Id
				WHERE pathunits.Path_Id = @ActivePath
				  AND pu.Non_Productive_Reason_TREE IS NOT NULL


				  SELECT @StartTime	 =StartTime , 
						@EndTime			= 	EndTime,		
						@ReasonLevel1		= 	ReasonLevel1	,
						@UserId =  UserId,
						@ReasonTreeDataId = ERTDataId
				FROM	@InsertedItems 
				WHERE	Idx= @Idx



				SET @LoopCnt = 1
				-- Loop through the list of units in the active Path
				WHILE @LoopCnt <= (Select Max(Idx) from @Units)
				BEGIN
							SELECT @PUID = PUID FROM @Units WHERE Idx = @LoopCnt

								BEGIN TRY
									EXEC dbo.spServer_DBMgrUpdNonProductiveTime 
													 @NPDetId			= Null				
													,@PUId				= @PUId 	
													,@StartTime			= @StartTime		
													,@EndTime			= @EndTime			
													,@ReasonLevel1		= @ReasonLevel1		
													,@ReasonLevel2		= Null				
													,@ReasonLevel3		= Null				
													,@ReasonLevel4		= Null				
													,@TransactionType	= 1					
													,@TransNum			= 0					
													,@UserId			= @UserId			
													,@CommentId			= 0					
													,@ERTDataId			= @ReasonTreeDataId	
													,@EntryOn			= @Now	
													,@NPTGroupId		= Null				
													,@ReturnAllResults	=  0
								END TRY
								BEGIN CATCH
									SET @error = 1
								END CATCH
								IF @error = 1
									BREAK
						SET @LoopCnt= @LoopCnt + 1
				END

				DELETE FROM @Units
				SET @Idx = @Idx +1
		END
	END



END

GO
DISABLE TRIGGER [dbo].[TRI_Local_NonProductiveDetail_FollowActivePath]
    ON [dbo].[NonProductive_Detail];


GO
CREATE TRIGGER [dbo].[NonProductive_Detail_History_Upd]
 ON  [dbo].[NonProductive_Detail]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 436
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into NonProductive_Detail_History
 	  	   (Comment_Id,End_Time,Entry_On,Event_Reason_Tree_Data_Id,NPDet_Id,NPT_Group_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Entry_On,a.Event_Reason_Tree_Data_Id,a.NPDet_Id,a.NPT_Group_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[NonProductive_Detail_History_Del]
 ON  [dbo].[NonProductive_Detail]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 436
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into NonProductive_Detail_History
 	  	   (Comment_Id,End_Time,Entry_On,Event_Reason_Tree_Data_Id,NPDet_Id,NPT_Group_Id,PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Entry_On,a.Event_Reason_Tree_Data_Id,a.NPDet_Id,a.NPT_Group_Id,a.PU_Id,a.Reason_Level1,a.Reason_Level2,a.Reason_Level3,a.Reason_Level4,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
-----------------------------------------------------------------------------------------------------------------------
--Create Trigger
-----------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER [dbo].[TRI_NonProductive_Detail]
ON [dbo].[NonProductive_Detail]
AFTER INSERT, UPDATE, DELETE

AS
BEGIN

PRINT 'Trigger In Progress'

SET NOCOUNT ON;


DECLARE 
	@OLDSTART_DATETIME DATETIME,
	@OLDEND_DATETIME   DATETIME,
	@UPDATESTATUS	   NVARCHAR(25),
	@START_DATETIME    DATETIME,
	@END_DATETIME      DATETIME,
	@UNIT_ID           INT,
	@Status_Schedule_Id INT,
	@PREVIOUSStatus_Schedule_Id INT

DECLARE @insertedItems TABLE (  StartTime			DATETIME				,
								EndTime				DATETIME				,
								UNITId				INT						,
								--UpdateStatus		NVARCHAR(25)		,
								--LineStatusId		INT			,
								NPDetId         	INT			,
								RcdIdx				INT IDENTITY	)


DECLARE @DeletedItems TABLE (	StartTime			DATETIME				,
								EndTime				DATETIME				,
								Unit_Id				INT						,
								StatusScheduleId	INT			,
								NPDetId				INT						,
								NPTStartTime		DATETIME				,
								NPTEndTime			DATETIME				,
								NPTUserId			INT				,
								RcdIdx				INT IDENTITY	)

DECLARE @idx	INT			, 			@error										INT

------------------------------------------------------------------------------------------------------------
-- Get information from NONPRODUCTIVE TABLE
------------------------------------------------------------------------------------------------------------

SELECT	@OldStart_DateTime	= D.Start_Time	,
		@OLDEND_DATETIME	= D.End_Time	,
		@UNIT_ID		    = D.PU_Id

FROM DELETED AS D

-- Delete LS Records when a NPT is removed
	IF EXISTS( SELECT * 
				FROM Deleted D
				LEFT JOIN NonProductive_Detail npd	WITH(NOLOCK) ON NPD.NPDET_Id = d.NPDET_Id
				WHERE NPD.NPDET_Id IS NULL)
	BEGIN
       PRINT 'INSIDE Delete'

	   INSERT INTO @DeletedItems(
									StartTime	,
									EndTime		,
									Unit_Id		,
									NPDetId)
		SELECT	d.Start_Time,
				d.End_Time,
				d.PU_Id,
				d.NPDet_Id				 
		FROM Deleted D
		LEFT JOIN dbo.NonProductive_Detail npd	WITH(NOLOCK)
				ON npd.NPDet_Id = d.NPDet_Id
		        WHERE npd.NPDet_Id IS NULL

		UPDATE D
			SET 
			    StatusScheduleId = Status_Schedule_Id, --SHOULD THIS BE SET TO NULL WHEN NPT RECORD IS DELETED
				StartTime = D.StartTime,
				EndTime = LS.End_DATETime
		FROM  @DeletedItems D
		JOIN dbo.Local_PG_Line_Status LS WITH(NOLOCK)
		ON D.UNIT_Id = LS.Unit_Id AND D.StartTime = LS.Start_DateTime
	END

-- Get information from new NPT RECORD
	------------------------------------------------------------------------------------------------------------
	INSERT INTO @insertedItems ( StartTime							,
								 EndTime							,
								 UNITId								,
								 NPDetId					)
	SELECT						i.Start_time	,
								i.End_Time		,
								i.PU_Id			,
								i.NPDet_Id 
	FROM Inserted i
						 										
	SET @Idx = 1

	WHILE @Idx <= (SELECT COUNT(*) FROM @insertedItems)
	BEGIN

			SELECT	@START_DATETIME		= StartTime 		,
					@END_DATETIME		= EndTime			,
					@UNIT_ID			= UNITId				
			FROM @insertedItems
			WHERE RcdIdx = @idx 
      
	       -- Get SCHEDULE ID if it exists	
			------------------------------------------------------------------------------------------------------------
			SELECT TOP 1 @Status_Schedule_Id = Status_Schedule_Id
				FROM dbo.Local_PG_Line_Status	WITH(NOLOCK)
				WHERE UNIT_Id		= @UNIT_Id -- @OldPUId 
				AND Start_DATETime	= @OldStart_DateTime 

			SELECT TOP 1 @PREVIOUSStatus_Schedule_Id = Status_Schedule_Id
				FROM dbo.Local_PG_Line_Status	WITH(NOLOCK)
				WHERE UNIT_Id		= @UNIT_Id -- @OldPUId 
				AND End_DATETime	= @OldStart_DateTime

	-- Create new record when transaction is 'New'
			------------------------------------------------------------------------------------------------------------
			IF	@Status_Schedule_Id IS NULL
				AND @OldStart_DateTime IS NULL
		BEGIN
		INSERT INTO dbo.Local_PG_Line_Status ( 
			START_DATETIME      , 
			LINE_STATUS_ID      ,
			UPDATE_STATUS       ,
			UNIT_ID             ,
			END_DATETIME        )

		SELECT
		npd.Start_Time,
		p.PHRASE_ID,
		'NEW',
		npd.PU_ID,
		npd.END_TIME
		FROM NonProductive_Detail npd
		JOIN DBO.EVENT_REASONS  e WITH(NOLOCK) ON e.Event_Reason_Id = npd.REASON_LEVEL1
		JOIN dbo.PHRASE	p WITH(NOLOCK) ON p.Phrase_Value = e.Event_Reason_Name

		PRINT 'Insert Successfull'
		END

           -- Update existing record based on new information
			------------------------------------------------------------------------------------------------------------
			ELSE IF		( @UpdateStatus = 'UPDATE' OR	@UpdateStatus = 'NEW' )
					AND ( @OldEnd_DATETime <> @End_DATETime OR @OldStart_DATETime <> @Start_DATETime )
					AND  @Status_Schedule_Id IS NOT NULL
			BEGIN
			UPDATE dbo.Local_PG_Line_Status
			SET 
				START_DATETIME     = NPd.Start_Time,
				Update_Status      = 'UPDATE',
				END_DATETIME	   = NPd.End_Time
				FROM dbo.NonProductive_Detail as npd
				JOIN dbo.local_pg_line_status LPS	WITH(NOLOCK) 
				ON npd.PU_Id = LPS.UNIT_Id AND LPS.Start_DATETime = npd.Start_Time

          PRINT 'Update SUCCESSFUL'
		  END
END
END
GO
DISABLE TRIGGER [dbo].[TRI_NonProductive_Detail]
    ON [dbo].[NonProductive_Detail];

