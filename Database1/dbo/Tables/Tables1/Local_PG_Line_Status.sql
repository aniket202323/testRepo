CREATE TABLE [dbo].[Local_PG_Line_Status] (
    [Status_Schedule_Id] INT          IDENTITY (1, 1) NOT NULL,
    [Start_DateTime]     DATETIME     NOT NULL,
    [Line_Status_Id]     INT          NOT NULL,
    [Update_Status]      VARCHAR (50) NOT NULL,
    [Unit_Id]            INT          NOT NULL,
    [End_DateTime]       DATETIME     NULL,
    CONSTRAINT [PK_Local_PG_Line_Status] PRIMARY KEY CLUSTERED ([Status_Schedule_Id] ASC)
);


GO

--------------------------------------------------------------------------------------------------
-- Trigger: TRI_Local_PG_Line_Status
--------------------------------------------------------------------------------------------------
-- Author				: Arido Software
-- Date created			: 2016-12-14
-- Version 				: Version 1.0
-- Type					: Trigger
-- Description			: Creates records on NonProductive_Detail table for all inserts/updates of Local_PG_Line_Status table
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2016-12-14		Arido Software			Initial Release
-- 1.1			2018-12-18		Arido Software			Insert Converter Id on NPT table.
-- 1.2			2018-01-03		Fernando Rio			Added iteration on the Inserted rows
-- 1.3			2019-01-18		Martin Casalis			FO-03717: Fixed update of NPT records
-- 1.4			2019-02-13		Martin Casalis			Added NPT Deletion feature
--================================================================================================
--------------------------------------------------------------------------------------------------


CREATE TRIGGER [dbo].[TRI_Local_PG_Line_Status]
ON [dbo].[Local_PG_Line_Status]
AFTER INSERT, UPDATE, DELETE

AS

DECLARE 
		@OldPUId					INT				,
		@OldStartTime				DATETIME		,
		@OldEndTime					DATETIME		,
		@PUId						INT				,
		@StartTime					DATETIME		,
		@EndTime					DATETIME		,
		@Now						DATETIME		,
		@NPDetId					INT				,
		@PreviousNPDetId			INT				,
		@PreviousReasonLevel1		INT				,
		@PreviousStartTime			DATETIME		,
		@PreviousReasonTreeDataId	INT				,
		@ReasonTreeDataId			INT				,
		@ReasonLevel1				INT				,
		@OldReasonLevel1			INT				,
		@UpdateStatus				NVARCHAR(25)	,
		@UserId						INT				    --,
		--@ConvId				INT				,
		--@OldConvId			INT
		
	DECLARE @insertedItems TABLE (  StartTime			DATETIME				,
										EndTime				DATETIME				,
										PUId				INT						,
										UpdateStatus		NVARCHAR(25)		,
										LineStatusId		INT			,
										StatusScheduleId	INT			,
										RcdIdx				INT IDENTITY	)


	DECLARE @DeletedItems TABLE (	StartTime			DATETIME				,
									EndTime				DATETIME				,
									PUId				INT						,
									StatusScheduleId	INT			,
									NPDetId				INT						,
									NPTStartTime		DATETIME				,
									NPTEndTime			DATETIME				,
									NPTUserId			INT				,
									RcdIdx				INT IDENTITY	)

	DECLARE @idx										INT			,
			@error										INT


BEGIN

	SET @Now = GETDATE()

	-- Get information from Line Status to be modified
	------------------------------------------------------------------------------------------------------------
	SELECT	@OldStartTime	= d.Start_DateTime	,
			@OldEndTime		= d.End_DateTime	,
			@OldPUId		= d.Unit_id			,
			@UpdateStatus	= d.Update_Status
	FROM Deleted d
	
	SELECT	TOP 1
			@OldReasonLevel1	= e.Event_Reason_Id
		FROM Deleted			d 
		JOIN dbo.Phrase			p WITH(NOLOCK) ON p.Phrase_Id = d.Line_Status_Id 
		JOIN dbo.Event_Reasons	e WITH(NOLOCK) ON p.Phrase_Value = e.Event_Reason_Name

	-- Delete NPT Records when a LS is removed
	IF EXISTS( SELECT * 
				FROM Deleted d
				LEFT JOIN dbo.Local_PG_Line_Status ls	WITH(NOLOCK)
														ON ls.Status_Schedule_Id = d.Status_Schedule_Id
				WHERE ls.Status_Schedule_Id IS NULL)
	BEGIN

		INSERT INTO @DeletedItems(
									StartTime	
										,EndTime
										,PUId	
										,StatusScheduleId)
		SELECT	d.Start_DateTime,
				d.End_DateTime,
				d.Unit_Id,
				d.Status_Schedule_Id				 
		FROM Deleted d
		LEFT JOIN dbo.Local_PG_Line_Status ls	WITH(NOLOCK)
												ON ls.Status_Schedule_Id = d.Status_Schedule_Id
		WHERE ls.Status_Schedule_Id IS NULL

		UPDATE d
			SET NPDetId = NPDet_Id,
				NPTStartTime = d.StartTime,
				NPTEndTime = npd.End_Time,
				NPTUserId = npd.User_Id
		FROM @DeletedItems d
		JOIN dbo.NonProductive_Detail npd	WITH(NOLOCK)	ON d.PUId = npd.PU_Id
															AND d.StartTime = npd.Start_Time

		SET @Idx = 1

		WHILE @Idx <= (SELECT COUNT(*) FROM @DeletedItems)
		BEGIN
		
			SELECT	@StartTime		= NPTStartTime 		,
					@EndTime		= NPTEndTime		,
					@PUId			= PUId				,
					@NPDetId		= NPDetId			,
					@UserId			= NPTUserId
			FROM @DeletedItems
			WHERE RcdIdx = @idx 

			BEGIN TRY
				EXEC dbo.spServer_DBMgrUpdNonProductiveTime 
								@NPDetId			= @NPDetId				
								,@PUId				= @PUId -- @ConvId				
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
				
			SET @idx = @idx + 1
		END
		
	END
	
	-- Get information from new Line Status
	------------------------------------------------------------------------------------------------------------
	INSERT INTO @insertedItems ( StartTime							,
								 EndTime							,
								 PUId								,
								 UpdateStatus						,
								 LineStatusId						,
								 StatusScheduleId					)
	SELECT						i.Start_Datetime	,
								i.End_DateTime		,
								i.Unit_id			,
								i.Update_Status		,
								i.Line_Status_Id	,
								i.Status_Schedule_Id 
	FROM Inserted i

						 										
	SET @Idx = 1

	WHILE @Idx <= (SELECT COUNT(*) FROM @insertedItems)
	BEGIN

			SELECT	@StartTime		= StartTime 		,
					@EndTime		= EndTime			,
					@PUId			= PUId				,
					@UpdateStatus	= UpdateStatus
			FROM @insertedItems
			WHERE RcdIdx = @idx 

			SELECT	TOP 1
					@ReasonLevel1		= e.Event_Reason_Id ,
					@ReasonTreeDataId	= et.Event_Reason_Tree_Data_Id
			FROM @insertedItems i --Inserted						i 
			JOIN dbo.Phrase							p	WITH(NOLOCK) ON p.Phrase_Id = i.LineStatusId 
			JOIN dbo.Event_Reasons					e	WITH(NOLOCK) ON p.Phrase_value = e.Event_Reason_Name
			LEFT JOIN dbo.Event_Reason_Tree_Data	et	WITH(NOLOCK) ON e.Event_Reason_Id = et.Event_Reason_Id
			WHERE RcdIdx = @Idx 

			-- Get User (EventMgr as default)
			------------------------------------------------------------------------------------------------------------
			SELECT TOP 1 @UserId = User_Id
				FROM	@insertedItems i
				JOIN	dbo.Local_PG_Line_Status_Comments	lsc WITH(NOLOCK) ON lsc.Status_Schedule_Id = i.StatusScheduleId 
				WHERE RcdIdx = @idx 

			IF @UserId IS NULL SELECT @UserId = User_Id FROM dbo.Users WITH(NOLOCK) WHERE Username LIKE 'EventMgr'
	
			-- Get NPT Detail Id if it exists	
			------------------------------------------------------------------------------------------------------------
			SELECT TOP 1 @NPDetId = NPDet_Id
				FROM dbo.NonProductive_Detail	WITH(NOLOCK)
				WHERE PU_Id		= @PUId -- @OldPUId 
				AND Start_Time	= @OldStartTime 

			SELECT TOP 1 @PreviousNPDetId			= NPDet_Id		,
						 @PreviousReasonLevel1		= Reason_Level1	,
						 @PreviousStartTime			= Start_Time	,
						 @PreviousReasonTreeDataId	= Event_Reason_Tree_Data_Id
				FROM dbo.NonProductive_Detail	WITH(NOLOCK)
				WHERE PU_Id		= @PUId -- @OldPUId 
				AND End_Time	= @OldStartTime 

			-- Create new record when transaction is 'New'
			------------------------------------------------------------------------------------------------------------
			IF		@UpdateStatus = 'NEW' 
				AND @NPDetId IS NULL
				AND @OldStartTime IS NULL
			BEGIN
	
					IF @EndTime IS NULL 
					BEGIN
						SET @EndTime = DATEADD(MONTH,6,GETDATE())
					END
							
					BEGIN TRY
						EXEC dbo.spServer_DBMgrUpdNonProductiveTime 
										 @NPDetId			= Null				
										,@PUId				= @PUId -- @ConvId				
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
			END

			-- Update existing record based on new information
			------------------------------------------------------------------------------------------------------------
			ELSE IF		(	@UpdateStatus = 'UPDATE' 
						OR	@UpdateStatus = 'NEW' )
					AND (	@OldEndTime <> @EndTime
						OR	@OldStartTime <> @StartTime
						OR	@OldReasonLevel1 <> @ReasonLevel1	)
					AND @NPDetId IS NOT NULL
			BEGIN

					IF @EndTime IS NULL 
					BEGIN
						SET @EndTime = DATEADD(MONTH,6,GETDATE()) 
					END		
			
					BEGIN TRY
						-- Update modified NPT record
						EXEC dbo.spServer_DBMgrUpdNonProductiveTime 
										@NPDetId			= @NPDetId		
										,@PUId				= @PUId -- @ConvId			
										,@StartTime			= @StartTime	
										,@EndTime			= @EndTime		
										,@ReasonLevel1		= @ReasonLevel1	
										,@ReasonLevel2		= Null			
										,@ReasonLevel3		= Null			
										,@ReasonLevel4		= Null			
										,@TransactionType	= 2				
										,@TransNum			= 0			
										,@UserId			= @UserId		
										,@CommentId			= 0				
										,@ERTDataId			= @ReasonTreeDataId	
										,@EntryOn			= @Now
										,@NPTGroupId		= Null		
										,@ReturnAllResults	= 0
					
						IF @PreviousNPDetId IS NOT NULL
						BEGIN			
							-- Update previous NPT record
							EXEC dbo.spServer_DBMgrUpdNonProductiveTime 
											@NPDetId			= @PreviousNPDetId		
											,@PUId				= @PUId -- @ConvId			
											,@StartTime			= @PreviousStartTime
											,@EndTime			= @StartTime	
											,@ReasonLevel1		= @PreviousReasonLevel1	
											,@ReasonLevel2		= Null			
											,@ReasonLevel3		= Null			
											,@ReasonLevel4		= Null			
											,@TransactionType	= 2				
											,@TransNum			= 0			
											,@UserId			= @UserId		
											,@CommentId			= 0				
											,@ERTDataId			= @PreviousReasonTreeDataId	
											,@EntryOn			= @Now
											,@NPTGroupId		= Null		
											,@ReturnAllResults	= 0
						END
					END TRY
					BEGIN CATCH
						SET @error = 1
					END CATCH
					IF @error = 1
						BREAK
			END


	SET @idx = @idx + 1

	END   -- WHILE


END