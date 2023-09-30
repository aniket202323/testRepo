
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE  PROCEDURE [dbo].[spLocal_ProductChangeEvent_pack] 
/* 
---------------------------------------------------------------------------------------------------------------------------------------
Updated By	:	Mike Thomas - Hariprasath Soundrapandian (TCS)
Date			:	2014-08-13
Version		:	1.1
Purpose		: 	[FO-01933] Changed the SP especially for packer units to avoid issues where 
				Production event gets deleted due to manual product change on packer unit. 
				The new SP name will be spLocal_ProductChangeEvent_pack and this SP should only be attached to packer unit.				
---------------------------------------------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-12-01
Version		:	4.7.1
Purpose		: 	Corrected logic bugs in code.
					if (@PUID_Splicers is NOT null) AND (@PUID_Splicers <> 0) -> Replaced OR by AND
					if (@PUID_Packer is NOT null) AND (@PUID_Packer <> 0) -> Replaced OR by AND
					if (@PUID_Process is NOT null) AND (@PUID_Process <> 0) -> Replaced OR by AND
					Also changed :
					SET @int_ProdIdx = (SELECT prod_id -> Was returning a list of Prod_Id, causing an error
					SET @int_ProdIdx = (SELECT TOP 1 prod_id -> Now returns last Prod_id
---------------------------------------------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc) - Tim Rogers
Date			:	2005-11-16
Version		:	4.7.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Added @RS_User_Id variable to use on all Resultsets.
					Added parameters to Resultset 1, 2 and 3
					Converted Resultset dates to Varchar(30) Model 120. yyyy-mm-dd hh:mi:ss(24h)
					Tim Rogers : Added references to @stls_puid to all join to crew_schedule or local_pg_line_status.
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated By	:	Normand Carbonneau - Eric Perron, Solutions et Technologies Industrielles Inc. 
Date			:	2005-03-17                                                         
Version		:	4.6.0 
Purpose		:	We need to propagate the update and delete of a grade change also. 
               We are using the history table. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         Ugo Lapierre, Solutions et Technologies Industrielles Inc. 
On                 Jan 21, 2005                                                         
Version         4.5.0 
                1)Verify that there are no events for timestamp +/-1 minute around product change 
                2)Verify there are no entry in crew_schedule +/-1 minute around product chnage 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         Ugo Lapierre, Solutions et Technologies Industrielles Inc. 
On                 Jan 10, 2005                                                         
Version         4.4.0 
                When version 4.3 has been done, some functionalities has been removed.  Those need to be reinstalled. 
                Some sites use last input "@puid_xxx" to know on which unit to do the product change. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         Ugo Lapierre, Solutions et Technologies Industrielles Inc. 
On                 Nov 11, 2004                                                         
Version         4.3.0, With version 215.5 or more recent of Proficy, There is no need to remove a second 
                to the timestamp passed to the SP.  Proficy do it itself.  So I removed this dateadd(ss,-1,time). 
                Before creating a column the SP will check the crew schedule table 1 second forward to see if a column 
                will or has been created.  If so, don't create the product change column. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         T. Rogers 
On                 Sept 1, 2004                                                         
Version         4.2.1, removed next status inputs 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         Ugo lapierre, Solutions et Technologies Industrielles inc. 
On                 July 19, 2004                                                         
Version         4.2.0 
Purpose :         Change the way we set the status to the new event.  Status is now define by the next status table 
                instead of from next status variable of the previous column.   
                I removed the result set sending a value in the next status variable 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         Ugo lapierre, Solutions et Technologies Industrielles inc. 
On                 March 10, 2004                                                         
Version         4.1.0 
Purpose :         The event created in the converter units at the product change, will be created at the 
                timestamp of 1 second before the brand change.  This will allow to have the right brand 
                associated the pad count. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by         Marc Charest, Solutions et Technologies Industrielles inc. 
On                 December 20, 2002                                                         
Version         4.0.0 
Purpose :         Like 2.0.1 but SP is no more creating grade changes 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by Rick Perreault, Solutions et Technologies Industrielles inc. 
On September 9, 2002                                                        Version 2.0.1 
Purpose :                 Updated sp so when it checks if there is already a column at that time, it looks 
                        only on the converter unit 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Updated by Melody Stevenson, Procter & Gamble 
On December 28, 2001                                                        Version 2.0.0 
Purpose :                 Updated SP to also change brand on the Process prod. unit 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
Created by Ugo Lapierre, Solutions et Technologies Industrielles inc. 
On ?                                                        Version 1.0.0 
Purpose :                 This SP create an event when the product change 
------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
TEST CODE :
declare @P1 varchar(511)
set @P1=NULL
exec spLocal_ProductChangeEvent_pack @P1 output, '57', '2005-12-13 15:30:33', '60', '2132', '59', '58', '61'
select @P1 
*/ 
@OutPutValue				varchar(30) output, 
@int_puid					int, 
@EventTime					datetime, 
@PUID_Target				int, 
--@varid_NS					int, 
@varid_ES					int, 
--@Prev_val_NS				varchar(30), 
@puid_Splicers				int, 
@puid_Packer				int, 
@puid_Process				int 

AS
SET NOCOUNT ON

DECLARE 
@strEventNum				varchar(30), 
@strLineStatus				varchar(30), 
@dteTimeLessSec				datetime, 
@int_Varid_ES				int, 
@int_ProdId					int, 
@dteLastProductChange		datetime, 
@int_ProdIdx				int, 
@LastModif					datetime, 
@DBTT_Id					int, 
@Start_Id					int, 
@Event_Id					int, 
@ActiveTime					datetime,		-- The DateTime of the column that will be created 
@LastTime					datetime,		-- The DateTime of the last Start_Time in PSH for the PU and Start_Id 
@Prod_id					int, 
@NewTime					datetime, 
@STLS_PUID					int,
@RS_User_id					int,
@AppVersion					varchar(30)		-- Used to retrieve the Proficy database Version

DECLARE @ResultSet3 TABLE
(
Start_Id					int,
PU_Id						int,
Product_Id					int,
Start_Time					datetime,
UpdateType					int Default 0,	-- (0=PreUpdate 1=PostUpdate)
User_Id						int,
SecondUserId				int,
TransType					int
)

--insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','START', 'START') 

IF @int_puid = 0 
	BEGIN 
		SELECT @OutPutValue = 'Pu_id is equal to 0' 
		RETURN 
	END 

-- Set Resultset User
SET @RS_User_id = (SELECT User_id FROM dbo.Users WITH (NOLOCK) WHERE UserName = 'ReliabilitySystem')

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WITH (NOLOCK) WHERE App_Name = 'Database')

SELECT @STLS_PUID = 
                CASE    WHEN        (CharIndex        ('STLS=', Extended_Info, 1)) > 0 
                        THEN        Substring        (Extended_Info, (CharIndex('STLS=', Extended_Info, 1) + 5), 
                CASE    WHEN         (CharIndex(';', Extended_Info, CharIndex('STLS=', Extended_Info, 1))) > 0 
                        THEN         (CharIndex(';', Extended_Info, CharIndex('STLS=', Extended_Info, 1)) - (CharIndex('STLS=', Extended_Info, 1) + 5)) 
                                                        ELSE         Len(Extended_Info) 
                                                        END ) 
                                        END 
        FROM dbo.Prod_Units WITH(NOLOCK)
        WHERE PU_ID = @int_puid 

-- Get the DateTime of the last modification in Production_Starts_History for the "STAL PU" 
SELECT @LastModif = MAX(Modified_On) FROM dbo.Production_Starts_History WITH(NOLOCK)WHERE PU_Id = @STLS_PUID 

-- Get the type of operation and Start_Id in the Production_Starts_History table (2=Insert, 3=Update, 4=Delete) 
SELECT @DBTT_Id = DBTT_Id, @Start_Id = Start_id FROM dbo.Production_Starts_History WITH(NOLOCK)
                                                WHERE (PU_Id = @STLS_PUID) AND (Modified_On = @LastModif) 


-- Start change FO-01933
-- The old common product change SP (For converter and packer) had the same segment for update and delete 
-- which is now divided as two different conditions for packer SP spLocal_ProductChangeEvent_pack
-- Update
IF @DBTT_Id = 3 
	BEGIN 
		SELECT @NewTime = start_time ,@Prod_id = prod_id FROM dbo.Production_Starts WITH(NOLOCK) WHERE Start_Id = @Start_id 
		--insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@NewTime', convert(varchar(25),@NewTime,126)) 
		
		-- Get the time of the previous row of PSH for the same PU and the same Start_Id 
		SELECT @LastTime = (SELECT TOP 1 Start_Time FROM dbo.Production_Starts_History WITH(NOLOCK)
		                                                WHERE (PU_Id = @STLS_PUID) AND (Modified_On < @LastModif) AND (Start_Id = @Start_Id) 
		                                                ORDER BY Modified_On DESC) 
		
		-- The time of the product change has been modified, so a new column will be created. We must delete the previous one. 
		--                 insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@LastModif', convert(varchar(19),@LastModif,126)) 
		--                 insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@LastTime', convert(varchar(19),@LastTime,126)) 
		--                 insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@DBTT_Id', @DBTT_Id) 
		
		IF @LastModif <> @LastTime 
			BEGIN 
				-- Get the Event_Id 
				SELECT @Event_Id = Event_Id FROM dbo.Events WITH(NOLOCK) WHERE (PU_Id = @int_puid) AND ([TimeStamp] = dateadd(ss,-1,@LastTime)) 
				--insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@Event_Id', @Event_Id) 
				
				-- Update the previous Event
				IF  @AppVersion LIKE '4%'
					BEGIN
						SELECT
						1,															-- Resultset Number
						0,															-- Not Used
						2,															-- TransactionType (1=Add 2=Update 3=delete)
						Event_Id,													-- EventId
						Event_Num,													-- EventNum
						@int_puid,													-- PU_Id
						CONVERT(Varchar(30),timestamp,120),							-- TimeStamp
						0,															-- Applied Product
						0,															-- Source Event
						0,															-- Event Status
						0,															-- Confirmed
						@RS_User_Id,												-- User_Id
						0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
						NULL,														-- Conformance
						NULL,														-- TestPctComplete
						NULL,														-- StartTime
						NULL,														-- TransNum
						NULL,														-- TestingStatus
						NULL,														-- Comment_Id
						NULL,														-- EventSubTypeId
						NULL,														-- Entry_On
						NULL,														-- ApprovedUserId
						NULL,														-- SecondUserId
						NULL,														-- ApprovedUserId
						NULL,														-- UserReasonId
						NULL,														-- UserSignOffId
						NULL														-- ExtendedInfo
						FROM dbo.Events WITH(NOLOCK) WHERE (PU_Id = @int_puid) AND ([TimeStamp] = DATEADD(ss,-1,@LastTime))
					END

				-- Execute all Resultset 3 in batch
				IF (SELECT COUNT(Start_Id) FROM @ResultSet3) > 0
					BEGIN
						IF @AppVersion LIKE '4%'
							BEGIN
								SELECT
								3,													-- Resultset Number
								Start_Id,											-- ProductionStart_Id
								PU_Id,												-- PU_Id
								Product_Id,											-- Product_Id
								CONVERT(Varchar(30),Start_Time,120),				-- Start_Time
								UpdateType,											-- UpdateType (0=PreUpdate 1=PostUpdate)
								User_Id,											-- User_Id
								SecondUserId,										-- SecondUserId
								TransType											-- TransType
								FROM @ResultSet3
							END
				END
				-- Clear processed resultsets from table
				DELETE FROM @ResultSet3
			END 
	END 

-- Delete
IF @DBTT_Id = 4 
	BEGIN 
		SELECT @NewTime = start_time ,@Prod_id = prod_id FROM dbo.Production_Starts WITH(NOLOCK) where Start_Id = @Start_id 
		--insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@NewTime', convert(varchar(25),@NewTime,126)) 
		
		-- Get the time of the previous row of PSH for the same PU and the same Start_Id 
		SELECT @LastTime = (SELECT TOP 1 Start_Time FROM dbo.Production_Starts_History WITH(NOLOCK)
		                                                WHERE (PU_Id = @STLS_PUID) AND (Modified_On < @LastModif) AND (Start_Id = @Start_Id) 
		                                                ORDER BY Modified_On DESC) 
		
		-- The time of the product change has been modified, so a new column will be created. We must delete the previous one. 
		--                 insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@LastModif', convert(varchar(19),@LastModif,126)) 
		--                 insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@LastTime', convert(varchar(19),@LastTime,126)) 
		--                 insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@DBTT_Id', @DBTT_Id) 
		
		IF @LastModif <> @LastTime 
			BEGIN 
				-- Get the Event_Id 
				SELECT @Event_Id = Event_Id FROM dbo.Events WITH(NOLOCK) WHERE (PU_Id = @int_puid) AND ([TimeStamp] = DATEADD(ss,-1,@LastTime)) 
				--insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','@Event_Id', @Event_Id) 
				
				-- Delete the previous Event
				IF  @AppVersion LIKE '4%'
					BEGIN
						SELECT
						1,															-- Resultset Number
						0,															-- Not Used
						3,															-- TransactionType (1=Add 2=Update 3=delete)
						Event_Id,													-- EventId
						Event_Num,													-- EventNum
						@int_puid,													-- PU_Id
						CONVERT(Varchar(30),timestamp,120),							-- TimeStamp
						0,															-- Applied Product
						0,															-- Source Event
						0,															-- Event Status
						0,															-- Confirmed
						@RS_User_Id,												-- User_Id
						0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
						NULL,														-- Conformance
						NULL,														-- TestPctComplete
						NULL,														-- StartTime
						NULL,														-- TransNum
						NULL,														-- TestingStatus
						NULL,														-- Comment_Id
						NULL,														-- EventSubTypeId
						NULL,														-- Entry_On
						-- Added P4 --
						NULL,														-- ApprovedUserId
						NULL,														-- SecondUserId
						NULL,														-- ApprovedUserId
						NULL,														-- UserReasonId
						NULL,														-- UserSignOffId
						NULL														-- ExtendedInfo
						FROM dbo.Events WITH(NOLOCK) WHERE (PU_Id = @int_puid) AND ([TimeStamp] = dateadd(ss,-1,@LastTime))
					END

				-- Execute all Resultset 3 in batch
				IF (SELECT COUNT(Start_Id) FROM @ResultSet3) > 0
					BEGIN
						IF @AppVersion LIKE '4%'
							BEGIN
								SELECT
								3,													-- Resultset Number
								Start_Id,											-- ProductionStart_Id
								PU_Id,												-- PU_Id
								Product_Id,											-- Product_Id
								CONVERT(Varchar(30),Start_Time,120),				-- Start_Time
								UpdateType,											-- UpdateType (0=PreUpdate 1=PostUpdate)
								User_Id,											-- User_Id
								-- Added P4 --
								SecondUserId,										-- SecondUserId
								TransType											-- TransType
								FROM @ResultSet3
							END
					END
					-- Clear processed resultsets from table
					DELETE FROM @ResultSet3
			END 
	END 
-- End change FO-01933

-- IF we are in a delete transaction , no need to continue 
IF @DBTT_Id = 4 
	BEGIN 
		SELECT @OutPutValue = '' 
		RETURN 
	END 

--Find the timestamp one seconde before brand change 
--select @dteTimeLessSec = dateadd(ss,-1,@EventTime)  remove by UL version 4.2.2 
SELECT @dteTimeLessSec = @EventTime 

--Find var_id of the event_status variables 
SELECT @int_Varid_ES = var_id FROM dbo.variables WITH(NOLOCK) WHERE extended_info = 'EVENTSTATUS' and pu_id=@int_puid 

--Start 4.2.2 add-in 
--verify if there is an event fired by crew schedule one second later if yes, don't create events 
IF EXISTS(select start_time FROM dbo.crew_schedule WITH(NOLOCK) WHERE pu_id = @stls_puid AND start_time = DATEADD(ss,1,@dteTimeLessSec)) 
	BEGIN 
		SELECT @OutPutValue = 'event exist' 
		RETURN 
	END 

IF EXISTS(select event_id FROM dbo.events WITH(NOLOCK) WHERE pu_id = @int_puid AND timestamp = DATEADD(ss,1,@dteTimeLessSec)) 
	BEGIN 
		SELECT @OutPutValue = 'event exist' 
		RETURN 
	END 
--end 4.2.2 add-in 

--Verify there is no entry in crew schedule around product change time 
IF NOT EXISTS(SELECT cs_id FROM dbo.crew_schedule WITH(NOLOCK) WHERE pu_id = @stls_puid AND end_time<DATEADD(mi,-1,@dteTimeLessSec) AND end_time>DATEADD(mi,1,@dteTimeLessSec) ) 
	BEGIN 	
		--Verify if there is already an event at end of shift time 
		--4.5.0 verify at +/- 1minutes around product change time 
		IF NOT EXISTS(SELECT event_id FROM dbo.events WITH(NOLOCK) where pu_id = @int_puid AND timestamp> DATEADD(mi,-1,@dteTimeLessSec) AND timestamp < DATEADD(mi,1,@dteTimeLessSec)) 
		BEGIN 
			--Yes we can create an event. 
			--Build event Num 
			SELECT @strEventNum = 'PC-' + REPLACE(CONVERT(varchar(30),@dteTimeLessSec,20) + CONVERT(varchar(6),@int_puid),' ','') 
			
			--Find line status 
			SELECT @strLineStatus = p.phrase_value 
			FROM dbo.local_pg_line_status lpls WITH(NOLOCK)
			JOIN dbo.phrase p WITH(NOLOCK) on p.phrase_id = lpls.line_status_id 
			WHERE lpls.start_datetime < @dteTimeLessSec 
			AND (lpls.end_datetime>=@dteTimeLessSec or lpls.end_datetime IS NULL) 
			AND lpls.unit_id = @stls_puid 
			      
			IF @strLineStatus is null 
				BEGIN 
					SELECT @strLineStatus = 'No status defined' 
				END 
			
			--Create columns and set status in the variables
			IF @AppVersion LIKE '4%'
				BEGIN
					select
					2,															-- Resultset Number
					@int_Varid_ES,												-- Var_Id
					@int_puid,													-- PU_Id
					@RS_User_Id,												-- User_Id
					0,															-- Canceled
					@strLineStatus,												-- Result
					CONVERT(Varchar(30),@dteTimeLessSec,120),					-- TimeStamp
					1,															-- TransactionType (1=Add 2=Update 3=Delete)
					0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
					Null,														-- SecondUserId
					Null,														-- TransNum
					Null,														-- EventId
					Null,														-- ArrayId
					Null														-- CommentId
					--------------------------------------------------------------------------------------------------
					SELECT
					1,															-- Resultset Number
					0,															-- Not Used
					1,															-- TransactionType (1=Add 2=Update 3=delete)
					0,															-- EventId
					@strEventNum,												-- EventNum
					@int_puid,													-- PU_Id
					CONVERT(Varchar(30),@dteTimeLessSec,120),					-- TimeStamp
					0,															-- Applied Product
					0,															-- Source Event
					0,															-- Event Status
					1,															-- Confirmed
					@RS_User_Id,												-- User_Id
					0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
					NULL,														-- Conformance
					NULL,														-- TestPctComplete
					NULL,														-- StartTime
					NULL,														-- TransNum
					NULL,														-- TestingStatus
					NULL,														-- Comment_Id
					NULL,														-- EventSubTypeId
					NULL,														-- Entry_On
					NULL,														-- ApprovedUserId
					NULL,														-- SecondUserId
					NULL,														-- ApprovedUserId
					NULL,														-- UserReasonId
					NULL,														-- UserSignOffId
					NULL														-- ExtendedInfo
				END
		END 
	END

--Some site use this SP to make product change. 
--If input variable like @puid_% are non zero and non null, we should change the brand on them. 
--Get the last grade change 
SELECT @dteLastProductChange = MIN(start_time) 
FROM dbo.production_starts WITH(NOLOCK)
WHERE pu_id = @int_puid AND start_time>= @EventTime 

SELECT @int_ProdId = prod_id FROM dbo.production_starts WITH(NOLOCK) WHERE pu_id = @int_puid AND start_time = @dteLastProductChange 

IF @int_ProdId IS NULL 
	BEGIN 
		SELECT @outputvalue=@strEventNum 
		RETURN 
	END 

IF @DBTT_Id IN (3,4) 
	BEGIN 
		-- insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','END', 'END') 
		SELECT @OutPutValue = '' 
		RETURN 
	END 

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','@int_ProdId',@int_ProdId) 
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','@dteLastProductChange',convert(varchar(30),@dteLastProductChange,20)) 

--verify each unit one by one 
IF (@PUID_Target IS NOT null) AND (@PUID_Target <> 0) 
	BEGIN 
		SET @int_ProdIdx = (SELECT TOP 1 prod_id 
		FROM dbo.production_starts WITH(NOLOCK)
		WHERE (pu_id = @puid_target) and (start_time <= @dteLastProductChange)
		ORDER BY Start_Time DESC)
		
		--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','@int_ProdIdx',@int_ProdIdx) 
		
		IF @int_ProdId <> @int_ProdIdx 
			BEGIN
				INSERT @ResultSet3
						(Start_Id, PU_Id, Product_Id, Start_Time, UpdateType, User_Id, SecondUserId, TransType)
						VALUES(0, @puid_target, @int_ProdId, @dteLastProductChange, 0, @RS_User_Id, NULL, NULL)
				--select 3,0,@puid_target,@int_ProdId,@dteLastProductChange,0 
				--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','Info ','product change on ' + convert(varchar(30),@puid_target)) 
			END 
	END 

--verify each unit one by one 
IF (@PUID_Splicers IS NOT null) AND (@PUID_Splicers <> 0)
	BEGIN 
		SET @int_ProdIdx = (SELECT TOP 1 prod_id 
		FROM dbo.production_starts WITH(NOLOCK)
		WHERE (pu_id = @PUID_Splicers) AND (start_time <= @dteLastProductChange)
		ORDER BY Start_Time DESC)
		
		--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','@int_ProdIdx',@int_ProdIdx) 
		
		IF @int_ProdId <> @int_ProdIdx 
			BEGIN
				INSERT @ResultSet3
						(Start_Id, PU_Id, Product_Id, Start_Time, UpdateType, User_Id, SecondUserId, TransType)
						VALUES(0, @PUID_Splicers, @int_ProdId, @dteLastProductChange, 0, @RS_User_Id, NULL, NULL)
				--select 3,0,@PUID_Splicers,@int_ProdId,@dteLastProductChange,0 
				--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','Info ','product change on ' + convert(varchar(30),@PUID_Splicers)) 
			END 
	END 

IF (@PUID_Packer IS NOT NULL) AND (@PUID_Packer <> 0)
	BEGIN 
		SET @int_ProdIdx = (SELECT TOP 1 prod_id 
		FROM dbo.production_starts WITH(NOLOCK)
		WHERE (pu_id = @PUID_Packer) AND (start_time <= @dteLastProductChange)
		ORDER BY Start_Time DESC)
		
		--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','@int_ProdIdx',@int_ProdIdx) 
		
		IF @int_ProdId<>@int_ProdIdx 
			BEGIN
				INSERT @ResultSet3
						(Start_Id, PU_Id, Product_Id, Start_Time, UpdateType, User_Id, SecondUserId, TransType)
						VALUES(0, @PUID_Packer, @int_ProdId, @dteLastProductChange, 0, @RS_User_Id, NULL, NULL)
				--select 3,0,@PUID_Packer,@int_ProdId,@dteLastProductChange,0 
				--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','Info ','product change on ' + convert(varchar(30),@PUID_Packer)) 
			END 
	END

IF (@PUID_Process IS NOT NULL) AND (@PUID_Process <> 0)
	BEGIN 
		SET @int_ProdIdx = (SELECT TOP 1 prod_id 
		FROM dbo.production_starts WITH(NOLOCK)
		WHERE (pu_id = @PUID_Process) AND (start_time <= @dteLastProductChange)
		ORDER BY Start_Time DESC)
		
		--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','@int_ProdIdx',@int_ProdIdx) 
		
		IF @int_ProdId<>@int_ProdIdx 
			BEGIN
				INSERT @ResultSet3
						(Start_Id, PU_Id, Product_Id, Start_Time, UpdateType, User_Id, SecondUserId, TransType)
						VALUES(0, @PUID_Process, @int_ProdId, @dteLastProductChange, 0, @RS_User_Id, NULL, NULL)
				--select 3,0,@PUID_Process,@int_ProdId,@dteLastProductChange,0 
				--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_ProductChangeEvent_pack','Info ','product change on ' + convert(varchar(30),@PUID_Process)) 
			END 
	END 

-- Execute all Resultset 3 in batch
IF (SELECT COUNT(Start_Id) FROM @ResultSet3) > 0
	BEGIN
		IF @AppVersion LIKE '4%'
			BEGIN
				SELECT
				3,													-- Resultset Number
				Start_Id,											-- ProductionStart_Id
				PU_Id,												-- PU_Id
				Product_Id,											-- Product_Id
				CONVERT(Varchar(30),Start_Time,120),				-- Start_Time
				UpdateType,											-- UpdateType (0=PreUpdate 1=PostUpdate)
				User_Id,											-- User_Id
				SecondUserId,										-- SecondUserId
				TransType											-- TransType
				FROM @ResultSet3
			END
	END

SELECT @outputvalue=@strEventNum 
--insert sti_test (Entry_On,sp_name,Parameter,Value) values(getdate(),'spLocal_ProductChangeEvent_pack','END', 'END') 

SET NOCOUNT OFF

