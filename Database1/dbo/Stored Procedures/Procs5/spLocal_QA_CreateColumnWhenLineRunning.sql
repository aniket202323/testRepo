
CREATE PROCEDURE dbo.spLocal_QA_CreateColumnWhenLineRunning

/*
--------------------------------------------------------------------------------------------
Stored Procedure Name: dbo.spLocal_QA_CreateColumnWhenLineRunning
Revisionn date who what
--------------------------------------------------------------------------------------------
Author		:	Alexandre Turgeon, Solutions et Technologies Industrielles inc.
Date created:	19 Mar 2007
Version 		:	1.0.0
SP Type		:	Display functionnality
Called by	:	Calculated variable
Description : 	Create attribute and variable display first column if the line is running
					and if the line wasn't running when the PO was activated
Editor tab spacing: 3
--------------------------------------------------------------------------------------------
*/
@Output        		varchar(25) OUTPUT,
@dteTimeStamp			DateTime,
@UpDownId				int,
@WaitId					int,
@AttrInitId				int = NULL,
@AttrTimestampId		int = NULL,
@VarInitId				int = NULL,
@VarTimestampId		int = NULL

AS
DECLARE
@Puid					int,
@PathId				int,
@Ppid					int,
@POStartTime		datetime,
@FlagTimestamp		datetime,
@FlagValue			int,
@LastStatus			datetime,
@Status				int,
@ColumnTimestamp	datetime,
@SheetId				int,
@AppVersion			varchar(30),
@User_id				int

SET NOCOUNT ON

SET @Output = ''

-- look for the last timestamp the flag was set to 1
SET @FlagTimestamp = (SELECT MAX(result_on) FROM dbo.tests WHERE var_id = @WaitId AND result = '1')

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_CreateColumnWhenLineRunning','@FlagTimestamp',convert(varchar(30),@FlagTimestamp,20))

-- if there is no timestamp or the last timestamp was before the PO start time, we exit
IF @FlagTimestamp < @POStartTime OR @FlagTimestamp IS NULL
BEGIN
	SET NOCOUNT OFF
	RETURN
END

-- retrieve execution path from the UpDown variable
SET @PathId = (SELECT prd.path_id
					FROM dbo.prdexec_paths prd
					  JOIN dbo.prod_lines pl ON pl.pl_id = prd.pl_id
					  JOIN dbo.prod_units pu ON pu.pl_id = pl.pl_id
					  JOIN dbo.variables v ON v.pu_id = pu.pu_id
					WHERE v.var_id = @UpDownId)

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_CreateColumnWhenLineRunning','@PathId',@PathId)

-- retrieve the active PO on this path and the time it was activated
SET @Ppid = (SELECT pp_id
				 FROM dbo.production_plan
				 WHERE pp_status_id = 3 AND path_id = @PathId)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_CreateColumnWhenLineRunning','@Ppid',@Ppid)

-- exit if there is no active PO
IF @Ppid IS NULL
BEGIN
	SET NOCOUNT OFF
	RETURN
END

SET @Puid = (SELECT pu_id FROM dbo.variables WHERE var_id = @UpDownId)

-- retrieve the PO start time
SET @POStartTime = (SELECT start_time
						  FROM dbo.production_plan_starts
						  WHERE pp_id = @Ppid AND pu_id = @Puid)
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_CreateColumnWhenLineRunning','@POStartTime',convert(varchar(30),@POStartTime,20))

-- verify if the line is running
SET @LastStatus = (SELECT MAX(result_on) FROM dbo.tests WHERE var_id = @UpDownId)
SET @Status = (SELECT result FROM dbo.tests WHERE var_id = @UpDownId AND result_on = @LastStatus)

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_CreateColumnWhenLineRunning','@LastStatus',convert(varchar(30),@LastStatus,20))
--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'spLocal_QA_CreateColumnWhenLineRunning','@Status',@Status)

-- if the line started running after the PO was activated, we need to create the first
-- attribute and variable columns
IF @Status = 1
BEGIN
	SET @User_id = (SELECT User_id FROM dbo.Users WHERE UserName = 'system utility')
	SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

	SET @ColumnTimestamp = GETDATE()

	-- clear the WaitFirstColumn flag
	IF @AppVersion LIKE '4%'
	BEGIN
		SELECT
		2,															-- Resultset Number
		@WaitId,													-- Var_Id
		@Puid,													-- PU_Id
		@User_id,												-- User_Id
		0,															-- Canceled
		0,															-- Result
		@FlagTimestamp,										-- TimeStamp
		1,															-- TransactionType (1=Add 2=Update 3=Delete)
		0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
		-- Added P4 --
		NULL,														-- SecondUserId
		NULL,														-- TransNum
		NULL,														-- EventId
		NULL,														-- ArrayId
		NULL														-- CommentId
	END
	ELSE
	BEGIN
		SELECT
		2,															-- Resultset Number
		@WaitId,													-- Var_Id
		@Puid,													-- PU_Id
		@User_id,												-- User_Id
		0,															-- Canceled
		0,															-- Result
		@FlagTimestamp,										-- TimeStamp
		1,															-- TransactionType (1=Add 2=Update 3=Delete)
		0															-- UpdateType (0=PreUpdate 1=PostUpdate)
	END

	-- create the atttribute column
	IF @AttrInitId IS NOT NULL
	BEGIN
		SET @SheetId = (SELECT sheet_id FROM dbo.sheet_variables WHERE var_id = @AttrInitId)

		IF @AppVersion LIKE '4%'
		BEGIN
			SELECT
			2,															-- Resultset Number
			@AttrInitId,											-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			1,															-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
			-- Added P4 --
			NULL,														-- SecondUserId
			NULL,														-- TransNum
			NULL,														-- EventId
			NULL,														-- ArrayId
			NULL														-- CommentId
	
			SELECT
			2,															-- Resultset Number
			@AttrTimestampId,										-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			@LastStatus,											-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
			-- Added P4 --
			NULL,														-- SecondUserId
			NULL,														-- TransNum
			NULL,														-- EventId
			NULL,														-- ArrayId
			NULL														-- CommentId
	
			SELECT 7, @SheetId, @User_id, 1, @LastStatus, 0
		END
		ELSE
		BEGIN
			SELECT
			2,															-- Resultset Number
			@AttrInitId,											-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			1,															-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0															-- UpdateType (0=PreUpdate 1=PostUpdate)
	
			SELECT
			2,															-- Resultset Number
			@AttrTimestampId,										-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			@LastStatus,											-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0															-- UpdateType (0=PreUpdate 1=PostUpdate)
	
			SELECT 7, @SheetId, @User_id, 1, @LastStatus, 0
		END
	END

	-- create the variable column
	IF @VarInitId IS NOT NULL
	BEGIN
		SET @SheetId = (SELECT sheet_id FROM dbo.sheet_variables WHERE var_id = @VarInitId)

		IF @AppVersion LIKE '4%'
		BEGIN
			SELECT
			2,															-- Resultset Number
			@VarInitId,												-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			1,															-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
			-- Added P4 --
			NULL,														-- SecondUserId
			NULL,														-- TransNum
			NULL,														-- EventId
			NULL,														-- ArrayId
			NULL														-- CommentId
	
			SELECT
			2,															-- Resultset Number
			@VarTimestampId,										-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			@LastStatus,											-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0,															-- UpdateType (0=PreUpdate 1=PostUpdate)
			-- Added P4 --
			NULL,														-- SecondUserId
			NULL,														-- TransNum
			NULL,														-- EventId
			NULL,														-- ArrayId
			NULL														-- CommentId
	
			SELECT 7, @SheetId, @User_id, 1, @LastStatus, 0
		END
		ELSE
		BEGIN
			SELECT
			2,															-- Resultset Number
			@VarInitId,												-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			1,															-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0															-- UpdateType (0=PreUpdate 1=PostUpdate)
	
			SELECT
			2,															-- Resultset Number
			@VarTimestampId,										-- Var_Id
			@Puid,													-- PU_Id
			@User_id,												-- User_Id
			0,															-- Canceled
			@LastStatus,											-- Result
			@LastStatus,											-- TimeStamp
			1,															-- TransactionType (1=Add 2=Update 3=Delete)
			0															-- UpdateType (0=PreUpdate 1=PostUpdate)
	
			SELECT 7, @SheetId, @User_id, 1, @LastStatus, 0
		END
	END
END

SET NOCOUNT OFF

