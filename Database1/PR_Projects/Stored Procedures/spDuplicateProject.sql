/* MODULE: DuplicateProject.sql */

/* SYNPOSIS
 * Duplicate a project including its content list.
 * Returns the Key value of the new project.
 * END SYNOPSIS */

/* HISTORY
   Created Sep 12, 2012 by ll:
   END HISTORY */

--DROP PROCEDURE [PR_Projects].[spDuplicateProject]
--GO

CREATE PROCEDURE [PR_Projects].[spDuplicateProject] (
-- PARAMETERS
   @OrigProjectId        UNIQUEIDENTIFIER, -- The ProjectId GUID of the project to be duplicated
   @ProjectId            UNIQUEIDENTIFIER, -- The GUID of the new project
   @ProjectName          NVARCHAR(50),     -- The new project name
   @Description          NVARCHAR(255),    -- The new project description
   @LastUpdatedAuthor    NVARCHAR(255),    -- The Person.S95Id of the person creating the project copy
   @LastUpdatedTimestamp DATETIME2,        -- The update timestamp
   @debug                BIT = 0,          -- if 1, print debug statements
   @test                 BIT = 0           -- if 1, do not actually add any records
-- END PARAMETERS 
)
AS
BEGIN

   DECLARE @projectKey     BIGINT,
           @origProjectKey BIGINT,
           @trancount      INT,
           @procName       VARCHAR(20),
           @trxName        VARCHAR(20),
		   @message        VARCHAR(4000),
		   @ERROR_NBR_RECORD_NOTFOUND INT = 50104

   SET NOCOUNT ON

   SELECT @ProcName = 'spDuplicateProject: ', 
          @TrxName = 'DuplicateProject',
          @projectKey = -1

   -- Handle nested transactions
   SET @trancount = @@trancount

	-- check that ProjectId exists
	IF NOT EXISTS (SELECT 1 FROM [PR_Projects].[ProjectInfo] WHERE [ProjectId] = @OrigProjectId)
	BEGIN	
	   SET @message = @ProcName + 'ProjectId ''' + CONVERT(VARCHAR(40),@OrigProjectId) + ''' not found.'
	   IF (@debug = 1) PRINT @message
	   RAISERROR('%d: %s',11,2, @ERROR_NBR_RECORD_NOTFOUND, @message)
	   -- A -1 projectKey returned means that the ProjectInfo record was not found
	   SELECT @projectKey AS NewProjectKey
	   RETURN
	END

	BEGIN try
      IF @trancount = 0
      BEGIN
         IF (@debug = 1) PRINT @ProcName + 'BEGIN TRANSACTION'
         BEGIN TRANSACTION
      END
      ELSE
      BEGIN
         IF (@debug = 1) PRINT @ProcName + 'SAVE TRANSACTION ' + @TrxName
         SAVE TRANSACTION @ProcName
      END

-- Get the Key of the original ProjectInfo record
   SELECT @origProjectKey = [Key] 
     FROM [PR_Projects].[ProjectInfo]
    WHERE [ProjectId] = @OrigProjectId

   -- Create ProjectInfo record
   IF (@debug = 1) PRINT @ProcName + 'INSERT INTO [PR_Projects].[ProjectInfo]'
   INSERT INTO [PR_Projects].[ProjectInfo] (
      [ProjectId],
      [Name],
      [Description],
      [VersionMajor],
      [VersionMinor],
	  [LastUpdatedAuthor],
	  [LastUpdatedTimestamp]
   ) SELECT
      @ProjectId,
      @ProjectName,
      @Description,
	  [VersionMajor],
      [VersionMinor],
      @LastUpdatedAuthor,
	  @LastUpdatedTimestamp
     FROM [PR_Projects].[ProjectInfo]
    WHERE [Key] = @origProjectKey

   -- Get the Key of the new ProjectInfo record
   SELECT @projectKey = @@IDENTITY

   -- Duplicate the orginal project content list in ProjectContent 
   IF (@debug = 1) PRINT @ProcName + 'INSERT INTO [PR_Projects].[ProjectContent]'
   IF (@test = 0)
   INSERT INTO [PR_Projects].[ProjectContent] (
      [ProjectKey],
      [LDAP],
      [ContentType],
      [Name],
      [Description]
   ) 
   SELECT
      @projectKey,
      [LDAP],
      [ContentType],
      [Name],
      [Description]
    FROM [PR_Projects].[ProjectContent]
   WHERE [ProjectKey] = @origProjectKey

   -- Commit work
   IF (@debug = 1) PRINT @ProcName + 'Trancount = ' + convert(varchar(5),@trancount)
      IF (@trancount = 0)
      BEGIN
	     IF (@test = 0)
		 BEGIN
		    IF (@debug = 1) PRINT @ProcName + 'COMMIT'
            COMMIT
		 END
		 ELSE
		 BEGIN
		    IF (@debug = 1) PRINT @ProcName + 'Just testing, ROLLBACK'
            ROLLBACK
		 END

      END

   END try
   BEGIN catch
      DECLARE @error   INT,
              @xstate  INT
      SELECT @error   = ERROR_NUMBER(),
             @message = ERROR_MESSAGE(),
             @xstate  = XACT_STATE()
      IF (@xstate = -1)
      BEGIN
         IF (@debug = 1) PRINT @ProcName + 'ROLLBACK'
         ROLLBACK
      END
      IF (@xstate = 1 AND @trancount = 0)
      BEGIN
         IF (@debug = 1) PRINT @ProcName + 'ROLLBACK'
         ROLLBACK
      END
      IF (@xstate = 1 AND @trancount > 0)
      BEGIN
         IF (@debug = 1) PRINT @ProcName + 'ROLLBACK ' + @TrxName
         ROLLBACK TRANSACTION TrxName
      END;
/* SQL Server 2012 only
      THROW
*/
      RAISERROR('%d: %s',16,1, @error, @message)
   END catch
   
   -- return the Key value of the newly created project (-1 if an error occurred)
   SELECT @projectKey AS NewProjectKey

END